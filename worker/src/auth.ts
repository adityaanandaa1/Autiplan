// Kunci publik Firebase Auth: dipakai untuk verifikasi ID token.
import { createRemoteJWKSet, jwtVerify } from 'jose';

const JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

export interface VerifiedToken {
  uid: string;
  projectId: string;
}

export interface VerifyOptions {
  jwksUrl?: string;
}

// Cache tingkat modul per URL, supaya JWKS tidak diambil tiap permintaan
// (jose sendiri meng-cache isinya di dalam fungsi yang dikembalikan).
const jwksCache = new Map<string, ReturnType<typeof createRemoteJWKSet>>();

function getJwks(jwksUrl: string): ReturnType<typeof createRemoteJWKSet> {
  let jwks = jwksCache.get(jwksUrl);
  if (!jwks) {
    jwks = createRemoteJWKSet(new URL(jwksUrl));
    jwksCache.set(jwksUrl, jwks);
  }
  return jwks;
}

// Memverifikasi Firebase ID token dengan `jose` terhadap JWKS
// securetoken@system.gserviceaccount.com.
// Syarat: alg RS256, iss = https://securetoken.google.com/<projectId>,
// aud = <projectId>, dan sub tidak kosong.
export async function verifyIdToken(
  jwt: string,
  projectId: string,
  options: VerifyOptions = {},
): Promise<VerifiedToken> {
  const jwks = getJwks(options.jwksUrl ?? JWKS_URL);
  const { payload } = await jwtVerify(jwt, jwks, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
    algorithms: ['RS256'],
  });
  const uid = payload.sub;
  if (typeof uid !== 'string' || uid.length === 0) {
    throw new Error('invalid_token');
  }
  return { uid, projectId };
}
