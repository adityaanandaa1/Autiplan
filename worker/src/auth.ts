// Copyright Google LLC. Lisensi Apache 2.0.
// Kunci publik Firebase Auth: dipakai auth.ts untuk verifikasi ID token.
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

// Memverifikasi Firebase ID token dengan `jose` terhadap JWKS
// securetoken@system.gserviceaccount.com.
// Syarat: iss = https://securetoken.google.com/<projectId>,
// aud = <projectId>, dan sub tidak kosong.
export async function verifyIdToken(
  jwt: string,
  projectId: string,
  options: VerifyOptions = {},
): Promise<VerifiedToken> {
  const jwksUrl = options.jwksUrl ?? JWKS_URL;
  const jwks = createRemoteJWKSet(new URL(jwksUrl));
  const expectedIssuer = `https://securetoken.google.com/${projectId}`;
  const { payload } = await jwtVerify(jwt, jwks, {
    issuer: expectedIssuer,
    audience: projectId,
  });
  const uid = payload.sub;
  if (typeof uid !== 'string' || uid.length === 0) {
    throw new Error('invalid_token');
  }
  return { uid, projectId };
}
