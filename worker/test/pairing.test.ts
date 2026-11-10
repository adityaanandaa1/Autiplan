import { afterEach, beforeEach, beforeAll, afterAll, describe, expect, test, vi } from 'vitest';
import { createServer, type Server } from 'node:http';
import { generateKeyPairSync } from 'node:crypto';
import { exportJWK, importPKCS8, SignJWT } from 'jose';
import { generate6DigitCode, handleClaimPairing, handleCreatePairing, normalizeIp, RateLimiter } from '../src/pairing.js';
import type { KVLike } from '../src/pairing.js';
import { verifyIdToken } from '../src/auth.js';
import type { FirestoreClient, PairingCodeDoc } from '../src/firestore.js';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class MemoryKV implements KVLike {
  private readonly store = new Map<string, { value: string; expiresAt?: number }>();

  async get(key: string): Promise<string | null> {
    const item = this.store.get(key);
    if (!item) return null;
    if (item.expiresAt !== undefined && Date.now() > item.expiresAt) {
      this.store.delete(key);
      return null;
    }
    return item.value;
  }

  async put(key: string, value: string, options?: { expirationTtl?: number }): Promise<void> {
    this.store.set(key, {
      value,
      expiresAt: options?.expirationTtl ? Date.now() + options.expirationTtl * 1000 : undefined,
    });
  }
}

class FakeFirestore {
  pairingCodes: Record<string, PairingCodeDoc> = {};
  children: Record<string, boolean> = {};
  claimCalled = 0;

  async checkChildExists(familyId: string, childId: string): Promise<boolean> {
    return this.children[`${familyId}/${childId}`] === true;
  }

  collisions = 0;
  saveAttempts = 0;

  async savePairingCode(code: string, data: PairingCodeDoc): Promise<boolean> {
    this.saveAttempts += 1;
    if (this.collisions > 0) {
      this.collisions -= 1;
      return false;
    }
    this.pairingCodes[code] = data;
    return true;
  }

  async getPairingCode(code: string): Promise<PairingCodeDoc | null> {
    return this.pairingCodes[code] ?? null;
  }

  claimResult = true;

  async claimPairingCodeAndRegisterDevice(): Promise<boolean> {
    this.claimCalled += 1;
    return this.claimResult;
  }
}

// ---------------------------------------------------------------------------
// generate6DigitCode
// ---------------------------------------------------------------------------

describe('generate6DigitCode', () => {
  test('selalu 6 digit dan memakai crypto.getRandomValues', () => {
    const calls: Uint32Array[] = [];
    const fakeCrypto = {
      getRandomValues(array: Uint32Array): Uint32Array {
        calls.push(array);
        array[0] = 123456;
        return array;
      },
    } as unknown as Crypto;

    const code = generate6DigitCode(fakeCrypto);
    expect(code).toBe('123456');
    expect(calls).toHaveLength(1);
    expect(calls[0]).toBeInstanceOf(Uint32Array);
  });

  test('1000 kode acak semuanya 6 digit', () => {
    for (let i = 0; i < 1000; i += 1) {
      const code = generate6DigitCode();
      expect(code.toString()).toMatch(/^\d{6}$/);
    }
  });
});


// ---------------------------------------------------------------------------
// handleCreatePairing
// ---------------------------------------------------------------------------

describe('handleCreatePairing', () => {
  test('menyimpan kode dan membalas {code, expiresAt}', async () => {
    const db = new FakeFirestore();
    db.children['uid-1/child-1'] = true;

    const res = await handleCreatePairing(
      'uid-1',
      { childId: 'child-1' },
      db as unknown as FirestoreClient,
      undefined,
      Date.now(),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { code: string; expiresAt: string };
    expect(body.code).toMatch(/^\d{6}$/);
    expect(new Date(body.expiresAt).getTime()).toBeGreaterThan(Date.now());
  });

  test('anak tidak ada → tidak menyimpan kode', async () => {
    const db = new FakeFirestore();
    const res = await handleCreatePairing(
      'uid-1',
      { childId: 'child-404' },
      db as unknown as FirestoreClient,
      undefined,
      Date.now(),
    );
    expect(res.status).toBe(404);
    expect(Object.keys(db.pairingCodes)).toHaveLength(0);
  });
});

describe('handleClaimPairing', () => {
  const NOW = Date.UTC(2026, 10, 10, 12, 0, 0);
  let db: FakeFirestore;
  let kv: MemoryKV;
  let limiter: RateLimiter;

  beforeEach(() => {
    db = new FakeFirestore();
    kv = new MemoryKV();
    limiter = new RateLimiter(kv);
    db.pairingCodes['123456'] = {
      familyId: 'family-1',
      childId: 'child-1',
      expiresAt: new Date(NOW + 5 * 60 * 1000).toISOString(),
      usedAt: null,
      updateTime: 't-1',
    };
    vi.spyOn(Date, 'now').mockReturnValue(NOW);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  test('kode valid → {familyId, childId} dan klaim commit dipanggil', async () => {
    const res = await handleClaimPairing(
      'child-uid',
      '1.2.3.4',
      { code: '123456' },
      db as unknown as FirestoreClient,
      limiter,
      NOW,
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { familyId: string; childId: string };
    expect(body.familyId).toBe('family-1');
    expect(body.childId).toBe('child-1');
    expect(db.claimCalled).toBe(1);
  });

  test('kode kedaluwarsa → 410 expired_code', async () => {
    db.pairingCodes['123456'] = {
      ...db.pairingCodes['123456'],
      expiresAt: new Date(NOW - 1000).toISOString(),
    };
    const res = await handleClaimPairing(
      'child-uid',
      '1.2.3.4',
      { code: '123456' },
      db as unknown as FirestoreClient,
      limiter,
      NOW,
    );
    expect(res.status).toBe(410);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('expired_code');
    expect(db.claimCalled).toBe(0);
  });

  test('kode sudah dipakai → 400 invalid_code', async () => {
    db.pairingCodes['123456'] = {
      ...db.pairingCodes['123456'],
      usedAt: new Date(NOW - 60 * 1000).toISOString(),
    };
    const res = await handleClaimPairing(
      'child-uid',
      '1.2.3.4',
      { code: '123456' },
      db as unknown as FirestoreClient,
      limiter,
      NOW,
    );
    expect(res.status).toBe(400);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('invalid_code');
    expect(db.claimCalled).toBe(0);
  });

  test('percobaan ke-6 per uid → 429 too_many_attempts', async () => {
    for (let i = 0; i < 5; i += 1) {
      await limiter.recordFailure('child-uid', '1.2.3.4');
    }
    const res = await handleClaimPairing(
      'child-uid',
      '1.2.3.4',
      { code: '123456' },
      db as unknown as FirestoreClient,
      limiter,
      NOW,
    );
    expect(res.status).toBe(429);
    const body = (await res.json()) as { error: string };
    expect(body.error).toBe('too_many_attempts');
    expect(db.claimCalled).toBe(0);
  });

  test('percobaan ke-21 per IP → 429 walaupun uid baru', async () => {
    for (let i = 0; i < 20; i += 1) {
      await limiter.recordFailure(`uid-${i}`, '9.9.9.9');
    }
    const res = await handleClaimPairing(
      'fresh-uid',
      '9.9.9.9',
      { code: '123456' },
      db as unknown as FirestoreClient,
      limiter,
      NOW,
    );
    expect(res.status).toBe(429);
    expect(db.claimCalled).toBe(0);
  });

  test('kegagalan uid lain pada IP yang sama tidak memblokir uid ini', async () => {
    await limiter.recordFailure('uid-lain', '1.2.3.4');
    const res = await handleClaimPairing(
      'child-uid',
      '1.2.3.4',
      { code: '123456' },
      db as unknown as FirestoreClient,
      limiter,
      NOW,
    );
    expect(res.status).toBe(200);
  });
});

describe('handleCreatePairing (diperketat)', () => {
  test('bentrok kode → ulangi dengan kode baru, maksimal 5 kali', async () => {
    const db = new FakeFirestore();
    db.children['uid-1/child-1'] = true;
    db.collisions = 2;
    const res = await handleCreatePairing('uid-1', { childId: 'child-1' }, db as unknown as FirestoreClient);
    expect(res.status).toBe(200);
    expect(db.saveAttempts).toBe(3);

    const db2 = new FakeFirestore();
    db2.children['uid-1/child-1'] = true;
    db2.collisions = 99;
    await expect(
      handleCreatePairing('uid-1', { childId: 'child-1' }, db2 as unknown as FirestoreClient),
    ).rejects.toThrow();
    expect(db2.saveAttempts).toBe(5);
  });

  test('childId tidak valid → 400', async () => {
    const db = new FakeFirestore();
    for (const childId of ['../x', '', 5, undefined, 'a/b']) {
      const res = await handleCreatePairing('uid-1', { childId }, db as unknown as FirestoreClient);
      expect(res.status).toBe(400);
    }
  });
});

describe('RateLimiter (diperketat)', () => {
  const NOW = Date.UTC(2026, 10, 10, 12, 0, 0);

  function claim(db: FakeFirestore, limiter: RateLimiter, code: unknown = '123456', uid = 'child-uid', ip = '1.2.3.4') {
    return handleClaimPairing(uid, ip, { code }, db as unknown as FirestoreClient, limiter, NOW);
  }

  function seeded() {
    const db = new FakeFirestore();
    db.pairingCodes['123456'] = {
      familyId: 'family-1',
      childId: 'child-1',
      expiresAt: new Date(NOW + 60_000).toISOString(),
      usedAt: null,
      updateTime: 't-1',
    };
    return db;
  }

  test('hitungan naik sebelum verifikasi selesai (permintaan paralel terlihat)', async () => {
    const kv = new MemoryKV();
    const db = seeded();
    let seenDuringLookup: string | null = 'belum';
    db.getPairingCode = async () => {
      seenDuringLookup = await kv.get('fail:uid:child-uid');
      return null;
    };
    await claim(db, new RateLimiter(kv));
    expect(seenDuringLookup).toBe('1');
  });

  test('klaim berhasil mengembalikan hitungan; kegagalan mempertahankannya', async () => {
    const kv = new MemoryKV();
    const limiter = new RateLimiter(kv);
    const db = seeded();
    expect((await claim(db, limiter)).status).toBe(200);
    expect(await kv.get('fail:uid:child-uid')).toBe('0');
    expect((await claim(db, limiter, '000000')).status).toBe(400);
    expect(await kv.get('fail:uid:child-uid')).toBe('1');
  });

  test('klaim gagal di commit (false) tetap terhitung', async () => {
    const kv = new MemoryKV();
    const db = seeded();
    db.claimResult = false;
    const res = await claim(db, new RateLimiter(kv));
    expect(res.status).toBe(400);
    expect(await kv.get('fail:uid:child-uid')).toBe('1');
  });

  test('format kode salah tetap dihitung sebagai kegagalan', async () => {
    const kv = new MemoryKV();
    const limiter = new RateLimiter(kv);
    const db = seeded();
    for (const bad of ['12', 123456, null, 'abcdef']) {
      expect((await claim(db, limiter, bad)).status).toBe(400);
    }
    expect(await kv.get('fail:uid:child-uid')).toBe('4');
    expect(db.claimCalled).toBe(0);
  });

  test('percobaan ke-6 ditolak 429 dan tidak menaikkan hitungan lagi', async () => {
    const kv = new MemoryKV();
    const limiter = new RateLimiter(kv);
    const db = seeded();
    for (let i = 0; i < 5; i += 1) await claim(db, limiter, '000000');
    expect((await claim(db, limiter)).status).toBe(429);
    expect(await kv.get('fail:uid:child-uid')).toBe('5');
  });

  test('tanpa binding KV → 503 unavailable; failOpen hanya untuk tes', async () => {
    const db = seeded();
    const res = await claim(db, new RateLimiter(null));
    expect(res.status).toBe(503);
    expect(await res.json()).toEqual({ error: 'unavailable' });
    expect(db.claimCalled).toBe(0);
    expect((await claim(db, new RateLimiter(null, { failOpen: true }))).status).toBe(200);
  });

  test('KV get/put melempar → 503, bukan galat tak terkendali', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const broken: KVLike = {
      get: async () => { throw new Error('kv down'); },
      put: async () => { throw new Error('kv down'); },
    };
    expect((await claim(seeded(), new RateLimiter(broken))).status).toBe(503);

    const putFails: KVLike = { get: async () => null, put: async () => { throw new Error('kv down'); } };
    expect((await claim(seeded(), new RateLimiter(putFails))).status).toBe(503);
  });

  test('IPv6 dikunci per /64', async () => {
    expect(normalizeIp('2001:db8:1:2:aaaa:bbbb:cccc:dddd')).toBe('2001:db8:1:2::/64');
    expect(normalizeIp('2001:0db8:0001:0002::1')).toBe('2001:db8:1:2::/64');
    expect(normalizeIp('2001:db8::1')).toBe('2001:db8:0:0::/64');
    expect(normalizeIp('::ffff:1.2.3.4')).toBe('1.2.3.4');
    expect(normalizeIp('1.2.3.4')).toBe('1.2.3.4');

    const kv = new MemoryKV();
    const limiter = new RateLimiter(kv);
    await limiter.recordFailure('u1', '2001:db8:1:2::1');
    await limiter.recordFailure('u2', '2001:db8:1:2:ffff::9');
    expect(await kv.get('fail:ip:2001:db8:1:2::/64')).toBe('2');
  });
});

// ---------------------------------------------------------------------------
// verifyIdToken
// ---------------------------------------------------------------------------

describe('verifyIdToken', () => {
  const PROJECT_ID = 'autiplan-bd927';
  let server: Server;
  let jwksUrl: string;
  let privateKeyPem: string;

  beforeAll(async () => {
    const pair = generateKeyPairSync('rsa', { modulusLength: 2048 });
    privateKeyPem = pair.privateKey
      .export({ type: 'pkcs8', format: 'pem' })
      .toString();
    const publicJwk = await exportJWK(pair.publicKey);
    const jwks = JSON.stringify({
      keys: [{ ...publicJwk, kid: 'test-key', alg: 'RS256', use: 'sig' }],
    });

    server = createServer((_req, res) => {
      res.setHeader('Content-Type', 'application/json');
      res.end(jwks);
    });
    await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
    const address = server.address();
    const port = typeof address === 'object' && address ? address.port : 0;
    jwksUrl = `http://127.0.0.1:${port}/jwks`;
  });

  afterAll(async () => {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  });

  async function signToken(audience: string): Promise<string> {
    const key = await importPKCS8(privateKeyPem, 'RS256');
    return new SignJWT({})
      .setProtectedHeader({ alg: 'RS256', kid: 'test-key' })
      .setIssuer(`https://securetoken.google.com/${PROJECT_ID}`)
      .setAudience(audience)
      .setSubject('anak-uid')
      .setIssuedAt()
      .setExpirationTime('1h')
      .sign(key);
  }

  test('token dengan aud benar diterima', async () => {
    const token = await signToken(PROJECT_ID);
    const verified = await verifyIdToken(token, PROJECT_ID, { jwksUrl });
    expect(verified.uid).toBe('anak-uid');
  });

  test('token dengan aud salah ditolak', async () => {
    const token = await signToken('proyek-lain');
    await expect(
      verifyIdToken(token, PROJECT_ID, { jwksUrl }),
    ).rejects.toThrow();
  });
});
