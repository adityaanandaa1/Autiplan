import type { FirestoreClient } from './firestore.js';

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

export class RateLimiter {
  constructor(private readonly kv: KVLike | null) {}

  async checkAndIncrement(
    uid: string,
    ip: string,
  ): Promise<{ allowed: boolean }> {
    if (!this.kv) return { allowed: true };

    const uidKey = `fail:uid:${uid}`;
    const ipKey = `fail:ip:${ip}`;

    const [uidCountStr, ipCountStr] = await Promise.all([
      this.kv.get(uidKey),
      this.kv.get(ipKey),
    ]);

    const uidCount = uidCountStr ? parseInt(uidCountStr, 10) : 0;
    const ipCount = ipCountStr ? parseInt(ipCountStr, 10) : 0;

    if (uidCount >= 5 || ipCount >= 20) {
      return { allowed: false };
    }
    return { allowed: true };
  }

  async recordFailure(uid: string, ip: string): Promise<void> {
    if (!this.kv) return;

    const uidKey = `fail:uid:${uid}`;
    const ipKey = `fail:ip:${ip}`;

    const [uidCountStr, ipCountStr] = await Promise.all([
      this.kv.get(uidKey),
      this.kv.get(ipKey),
    ]);

    const uidCount = (uidCountStr ? parseInt(uidCountStr, 10) : 0) + 1;
    const ipCount = (ipCountStr ? parseInt(ipCountStr, 10) : 0) + 1;

    await Promise.all([
      this.kv.put(uidKey, uidCount.toString(), { expirationTtl: 15 * 60 }),
      this.kv.put(ipKey, ipCount.toString(), { expirationTtl: 60 * 60 }),
    ]);
  }
}

export async function handleCreatePairing(
  callerUid: string,
  body: { childId?: string },
  firestore: FirestoreClient,
  cryptoObj: Crypto = crypto,
  nowMs: number = Date.now(),
): Promise<Response> {
  const childId = body.childId;
  if (!childId) {
    return new Response(JSON.stringify({ error: 'missing_child_id' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const childExists = await firestore.checkChildExists(callerUid, childId);
  if (!childExists) {
    return new Response(JSON.stringify({ error: 'child_not_found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const code = generate6DigitCode(cryptoObj).toString();
  const expiresAt = new Date(nowMs + 10 * 60 * 1000).toISOString();

  await firestore.savePairingCode(code, {
    familyId: callerUid,
    childId,
    expiresAt,
    usedAt: null,
  });

  return new Response(JSON.stringify({ code, expiresAt }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
}

export async function handleClaimPairing(
  childUid: string,
  clientIp: string,
  body: { code?: string },
  firestore: FirestoreClient,
  limiter: RateLimiter,
  nowMs: number = Date.now(),
): Promise<Response> {
  const code = body.code?.trim();
  if (!code || code.length !== 6) {
    await limiter.recordFailure(childUid, clientIp);
    return new Response(JSON.stringify({ error: 'invalid_code' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const { allowed } = await limiter.checkAndIncrement(childUid, clientIp);
  if (!allowed) {
    return new Response(JSON.stringify({ error: 'too_many_attempts' }), {
      status: 429,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const doc = await firestore.getPairingCode(code);
  if (!doc || doc.usedAt !== null) {
    await limiter.recordFailure(childUid, clientIp);
    return new Response(JSON.stringify({ error: 'invalid_code' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const expiresTime = new Date(doc.expiresAt).getTime();
  if (isNaN(expiresTime) || nowMs > expiresTime) {
    await limiter.recordFailure(childUid, clientIp);
    return new Response(JSON.stringify({ error: 'expired_code' }), {
      status: 410,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const nowIso = new Date(nowMs).toISOString();
  const success = await firestore.claimPairingCodeAndRegisterDevice({
    code,
    familyId: doc.familyId,
    childId: doc.childId,
    childUid,
    usedAt: nowIso,
    expiresAt: doc.expiresAt,
    updateTime: doc.updateTime ?? '',
  });

  if (!success) {
    await limiter.recordFailure(childUid, clientIp);
    return new Response(JSON.stringify({ error: 'invalid_code' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(
    JSON.stringify({ familyId: doc.familyId, childId: doc.childId }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
}
