import type { FirestoreClient } from './firestore.js';
import { CODE_PATTERN, ID_PATTERN } from './firestore.js';

export interface KVLike {
  get(key: string): Promise<string | null>;
  put(key: string, value: string, options?: { expirationTtl?: number }): Promise<void>;
}

export function generate6DigitCode(cryptoObj: Crypto = crypto): String {
  const array = new Uint32Array(1);
  cryptoObj.getRandomValues(array);
  const code = (array[0] % 1000000).toString().padStart(6, '0');
  return code;
}

// IPv6 dikelompokkan per /64 (pengguna biasa mendapat seluruh blok itu);
// alamat IPv4-mapped diperlakukan sebagai IPv4.
export function normalizeIp(ip: string): string {
  const v = ip.trim().toLowerCase();
  if (!v.includes(':')) return v;
  const mapped = v.match(/^::ffff:(\d+\.\d+\.\d+\.\d+)$/);
  if (mapped) return mapped[1];
  let groups: string[];
  if (v.includes('::')) {
    const [a, b] = v.split('::');
    const head = a ? a.split(':') : [];
    const tail = b ? b.split(':') : [];
    const fill = Math.max(8 - head.length - tail.length, 0);
    groups = [...head, ...Array<string>(fill).fill('0'), ...tail];
  } else {
    groups = v.split(':');
  }
  return groups.slice(0, 4).map((g) => g.replace(/^0+(?=.)/, '')).join(':') + '::/64';
}

export type LimitResult = 'ok' | 'limited' | 'unavailable';

const UID_LIMIT = 5;
const UID_TTL = 15 * 60;
const IP_LIMIT = 20;
const IP_TTL = 60 * 60;

// Catatan: KV tidak atomik, jadi ini pembatas upaya terbaik. Hitungan dinaikkan
// SEBELUM kode diverifikasi (jendela balapan jauh lebih sempit daripada
// "verifikasi dulu, hitung kemudian") dan dikurangi bila klaim berhasil.
export class RateLimiter {
  // failOpen hanya untuk tes: tanpa binding KV, semuanya diizinkan.
  constructor(
    private readonly kv: KVLike | null,
    private readonly options: { failOpen?: boolean } = {},
  ) {}

  private keys(uid: string, ip: string) {
    return { uidKey: `fail:uid:${uid}`, ipKey: `fail:ip:${normalizeIp(ip)}` };
  }

  private async bump(uid: string, ip: string, delta: 1 | -1, enforce: boolean): Promise<LimitResult> {
    if (!this.kv) return this.options.failOpen ? 'ok' : 'unavailable';
    const kv = this.kv;
    const { uidKey, ipKey } = this.keys(uid, ip);
    try {
      const [uidStr, ipStr] = await Promise.all([kv.get(uidKey), kv.get(ipKey)]);
      const uidCount = parseInt(uidStr ?? '0', 10) || 0;
      const ipCount = parseInt(ipStr ?? '0', 10) || 0;
      if (enforce && (uidCount >= UID_LIMIT || ipCount >= IP_LIMIT)) return 'limited';
      await Promise.all([
        kv.put(uidKey, Math.max(uidCount + delta, 0).toString(), { expirationTtl: UID_TTL }),
        kv.put(ipKey, Math.max(ipCount + delta, 0).toString(), { expirationTtl: IP_TTL }),
      ]);
      return 'ok';
    } catch (err) {
      console.error('rate limiter KV gagal:', err instanceof Error ? err.name : 'unknown');
      return 'unavailable';
    }
  }

  // Memesan satu percobaan: naikkan hitungan lebih dulu, tolak bila sudah di batas.
  reserve(uid: string, ip: string): Promise<LimitResult> {
    return this.bump(uid, ip, 1, true);
  }

  // Mengembalikan percobaan yang berhasil (tidak dihitung sebagai kegagalan).
  async release(uid: string, ip: string): Promise<void> {
    await this.bump(uid, ip, -1, false);
  }

  // Mencatat satu kegagalan secara langsung (dipakai tes dan jalur lain).
  async recordFailure(uid: string, ip: string): Promise<void> {
    await this.bump(uid, ip, 1, false);
  }
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

const MAX_CODE_ATTEMPTS = 5;

export async function handleCreatePairing(
  callerUid: string,
  body: Record<string, unknown>,
  firestore: FirestoreClient,
  cryptoObj: Crypto = crypto,
  nowMs: number = Date.now(),
): Promise<Response> {
  const childId = body.childId;
  if (typeof childId !== 'string' || !ID_PATTERN.test(childId)) {
    return json(400, { error: 'invalid_child_id' });
  }

  const childExists = await firestore.checkChildExists(callerUid, childId);
  if (!childExists) {
    return json(404, { error: 'child_not_found' });
  }

  const expiresAt = new Date(nowMs + 10 * 60 * 1000).toISOString();
  for (let attempt = 0; attempt < MAX_CODE_ATTEMPTS; attempt += 1) {
    const code = generate6DigitCode(cryptoObj).toString();
    const saved = await firestore.savePairingCode(code, {
      familyId: callerUid,
      childId,
      expiresAt,
      usedAt: null,
    });
    // false = bentrok dengan kode yang sudah ada; coba kode lain.
    if (saved !== false) return json(200, { code, expiresAt });
  }
  throw new Error('pairing_code_collision');
}

export async function handleClaimPairing(
  childUid: string,
  clientIp: string,
  body: Record<string, unknown>,
  firestore: FirestoreClient,
  limiter: RateLimiter,
  nowMs: number = Date.now(),
): Promise<Response> {
  // Hitungan naik sebelum apa pun diverifikasi; kegagalan (termasuk format
  // salah) tetap terhitung, hanya klaim yang berhasil mengembalikannya.
  const reserved = await limiter.reserve(childUid, clientIp);
  if (reserved === 'unavailable') return json(503, { error: 'unavailable' });
  if (reserved === 'limited') return json(429, { error: 'too_many_attempts' });

  const raw = body.code;
  const code = typeof raw === 'string' ? raw.trim() : '';
  if (!CODE_PATTERN.test(code)) {
    return json(400, { error: 'invalid_code' });
  }

  const doc = await firestore.getPairingCode(code);
  if (!doc || doc.usedAt !== null) {
    return json(400, { error: 'invalid_code' });
  }

  const expiresTime = new Date(doc.expiresAt).getTime();
  if (isNaN(expiresTime) || nowMs > expiresTime) {
    return json(410, { error: 'expired_code' });
  }

  const success = await firestore.claimPairingCodeAndRegisterDevice({
    code,
    familyId: doc.familyId,
    childId: doc.childId,
    childUid,
    usedAt: new Date(nowMs).toISOString(),
    expiresAt: doc.expiresAt,
    updateTime: doc.updateTime ?? '',
  });
  if (!success) {
    return json(400, { error: 'invalid_code' });
  }

  await limiter.release(childUid, clientIp);
  return json(200, { familyId: doc.familyId, childId: doc.childId });
}
