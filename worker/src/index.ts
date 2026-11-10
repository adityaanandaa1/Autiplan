import { verifyIdToken } from './auth.js';
import { FirestoreClient, getAccessToken, type ServiceAccount } from './firestore.js';
import { handleClaimPairing, handleCreatePairing, RateLimiter } from './pairing.js';
import { handleNotify } from './notify.js';

export interface Env {
  ATTEMPTS?: KVNamespace;
  FIREBASE_PROJECT_ID: string;
  FIREBASE_SERVICE_ACCOUNT?: string;
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// Mengembalikan objek JSON, atau null bila badan bukan objek (null, array, angka, dll).
async function readObject(request: Request): Promise<Record<string, unknown> | null> {
  try {
    const parsed: unknown = await request.json();
    if (typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)) {
      return parsed as Record<string, unknown>;
    }
  } catch {
    // badan kosong atau bukan JSON
  }
  return null;
}

async function route(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const match = (request.headers.get('Authorization') ?? '').match(/^Bearer\s+(.+)$/i);
  if (!match) return json(401, { error: 'unauthorized' });

  const projectId = env.FIREBASE_PROJECT_ID || 'autiplan-bd927';

  let callerUid: string;
  try {
    callerUid = (await verifyIdToken(match[1], projectId)).uid;
  } catch {
    return json(401, { error: 'unauthorized' });
  }

  let sa: ServiceAccount | null = null;
  if (env.FIREBASE_SERVICE_ACCOUNT) {
    try {
      sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT) as ServiceAccount;
    } catch {
      sa = null;
    }
  }

  // Satu token OAuth per permintaan (dan di-cache lintas permintaan di getAccessToken).
  let tokenPromise: Promise<string> | null = null;
  const tokenGetter = () => {
    if (!sa) return Promise.reject(new Error('missing_service_account'));
    tokenPromise ??= getAccessToken(sa);
    return tokenPromise;
  };
  const firestore = new FirestoreClient(projectId, tokenGetter);

  const path = url.pathname;
  const isPost = request.method === 'POST';

  if (isPost && path === '/notify') {
    const body = await readObject(request);
    if (!body) return json(400, { error: 'invalid_body' });
    return handleNotify(callerUid, body, firestore, projectId, tokenGetter);
  }

  if (isPost && path === '/pairing/create') {
    const body = await readObject(request);
    if (!body) return json(400, { error: 'invalid_body' });
    return handleCreatePairing(callerUid, body, firestore);
  }

  if (isPost && path === '/pairing/claim') {
    // Badan yang rusak tetap diproses sebagai kode kosong supaya terhitung gagal.
    const body = (await readObject(request)) ?? {};
    const limiter = new RateLimiter(env.ATTEMPTS ?? null);
    const clientIp = request.headers.get('CF-Connecting-IP') ?? 'unknown';
    return handleClaimPairing(callerUid, clientIp, body, firestore, limiter);
  }

  return json(404, { error: 'not_found' });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return await route(request, env);
    } catch (err) {
      // Hanya nama dan pesan galat kita sendiri; tidak ada token atau badan permintaan.
      console.error('internal error:', err instanceof Error ? `${err.name}: ${err.message}` : 'unknown');
      return json(500, { error: 'internal' });
    }
  },
};
