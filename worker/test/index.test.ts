import { afterEach, beforeEach, describe, expect, test, vi } from 'vitest';
import worker, { type Env } from '../src/index.js';
import type { KVLike } from '../src/pairing.js';

vi.mock('../src/auth.js', () => ({
  verifyIdToken: async (jwt: string) => {
    if (jwt !== 'good') throw new Error('bad');
    return { uid: 'uid-1', projectId: 'p' };
  },
}));

class MemoryKV implements KVLike {
  store = new Map<string, string>();
  async get(k: string) {
    return this.store.get(k) ?? null;
  }
  async put(k: string, v: string) {
    this.store.set(k, v);
  }
}

let fetchMock: ReturnType<typeof vi.fn>;
let kv: MemoryKV;

function env(over: Partial<Env> = {}): Env {
  return { FIREBASE_PROJECT_ID: 'p', ATTEMPTS: kv as unknown as KVNamespace, ...over };
}

function call(path: string, body?: unknown, opts: { auth?: string | null; method?: string; raw?: string } = {}) {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  const auth = opts.auth === undefined ? 'Bearer good' : opts.auth;
  if (auth) headers.Authorization = auth;
  return worker.fetch(
    new Request(`https://w.test${path}`, {
      method: opts.method ?? 'POST',
      headers,
      body: opts.raw ?? (body === undefined ? undefined : JSON.stringify(body)),
    }),
    env(),
  );
}

beforeEach(() => {
  kv = new MemoryKV();
  fetchMock = vi.fn(async () => new Response('{}', { status: 500 }));
  vi.stubGlobal('fetch', fetchMock);
  vi.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe('routing index', () => {
  test('tanpa header Authorization → 401', async () => {
    const res = await call('/notify', {}, { auth: null });
    expect(res.status).toBe(401);
  });

  test('token tidak valid → 401', async () => {
    const res = await call('/notify', {}, { auth: 'Bearer buruk' });
    expect(res.status).toBe(401);
  });

  test('rute tidak dikenal dan metode salah → 404', async () => {
    expect((await call('/tidak-ada', {})).status).toBe(404);
    expect((await call('/notify', undefined, { method: 'GET' })).status).toBe(404);
  });

  test('OPTIONS tidak lagi dijawab CORS', async () => {
    const res = await call('/notify', undefined, { method: 'OPTIONS' });
    expect(res.status).toBe(404);
    expect(res.headers.get('Access-Control-Allow-Origin')).toBeNull();
  });

  test.each([['null'], ['[]'], ['"teks"'], ['12'], ['bukan json']])(
    'badan %s di /notify dan /pairing/create → 400 invalid_body',
    async (raw) => {
      for (const path of ['/notify', '/pairing/create']) {
        const res = await call(path, undefined, { raw });
        expect(res.status).toBe(400);
        expect(await res.json()).toEqual({ error: 'invalid_body' });
      }
    },
  );

  test('id berisi ../ atau bukan string ditolak sebelum menyentuh Firestore', async () => {
    const bad = [
      { familyId: '../x', notificationId: 'n' },
      { familyId: 'f', notificationId: 'a/b' },
      { familyId: 'f', notificationId: 123 },
      { familyId: 'f' },
    ];
    for (const body of bad) {
      const res = await call('/notify', body);
      expect(res.status).toBe(400);
    }
    const res = await call('/pairing/create', { childId: '../children/x' });
    expect(res.status).toBe(400);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('claim: badan null / code bukan string / format salah → 400 invalid_code dan terhitung', async () => {
    for (const body of [null, { code: 123456 }, { code: '12345' }, { code: '12345a' }, { code: ['123456'] }]) {
      const res = await call('/pairing/claim', body);
      expect(res.status).toBe(400);
      expect(await res.json()).toEqual({ error: 'invalid_code' });
    }
    expect(kv.store.get('fail:uid:uid-1')).toBe('5');
    expect((await call('/pairing/claim', { code: 'x' })).status).toBe(429);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  test('claim tanpa binding KV → 503 unavailable (fail-closed)', async () => {
    const res = await worker.fetch(
      new Request('https://w.test/pairing/claim', {
        method: 'POST',
        headers: { Authorization: 'Bearer good' },
        body: JSON.stringify({ code: '123456' }),
      }),
      { FIREBASE_PROJECT_ID: 'p' },
    );
    expect(res.status).toBe(503);
    expect(await res.json()).toEqual({ error: 'unavailable' });
  });

  test('galat tak terduga → 500 {"error":"internal"} tanpa detail', async () => {
    // Tanpa service account, tokenGetter melempar saat Firestore dipakai.
    const res = await call('/notify', { familyId: 'f', notificationId: 'n' });
    expect(res.status).toBe(500);
    expect(await res.json()).toEqual({ error: 'internal' });
  });
});
