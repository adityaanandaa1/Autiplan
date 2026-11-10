import { verifyIdToken } from './auth.js';
import { FirestoreClient, getAccessToken, type ServiceAccount } from './firestore.js';
import { handleClaimPairing, handleCreatePairing, RateLimiter } from './pairing.js';
import { handleNotify } from './notify.js';

export interface Env {
  ATTEMPTS?: KVNamespace;
  FIREBASE_PROJECT_ID: string;
  FIREBASE_SERVICE_ACCOUNT?: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    const url = new URL(request.url);
    const authHeader = request.headers.get('Authorization') ?? '';
    const match = authHeader.match(/^Bearer\s+(.+)$/i);
    if (!match) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    const jwt = match[1];
    const projectId = env.FIREBASE_PROJECT_ID || 'autiplan-bd927';

    let callerUid: string;
    try {
      const verified = await verifyIdToken(jwt, projectId);
      callerUid = verified.uid;
    } catch {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    let sa: ServiceAccount | null = null;
    if (env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        sa = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT) as ServiceAccount;
      } catch {
        sa = null;
      }
    }

    const firestore = new FirestoreClient(projectId, async () => {
      if (!sa) throw new Error('missing_service_account');
      return getAccessToken(sa);
    });

    if (url.pathname === '/notify' && request.method === 'POST') {
      const body = (await request.json().catch(() => ({}))) as {
        familyId?: string;
        notificationId?: string;
      };
      const tokenGetter = async () => {
        if (!sa) throw new Error('missing_service_account');
        return getAccessToken(sa);
      };
      return handleNotify(
        callerUid,
        body,
        firestore,
        projectId,
        tokenGetter,
        fetch,
      );
    }

    const limiter = new RateLimiter(env.ATTEMPTS ?? null);
    const clientIp = request.headers.get('CF-Connecting-IP') ?? '127.0.0.1';

    if (url.pathname === '/pairing/create' && request.method === 'POST') {
      const body = (await request.json().catch(() => ({}))) as { childId?: string };
      return handleCreatePairing(callerUid, body, firestore);
    }

    if (url.pathname === '/pairing/claim' && request.method === 'POST') {
      const body = (await request.json().catch(() => ({}))) as { code?: string };
      return handleClaimPairing(callerUid, clientIp, body, firestore, limiter);
    }

    return new Response(JSON.stringify({ error: 'not_found' }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    });
  },
};
