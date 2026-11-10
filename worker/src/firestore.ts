import { importPKCS8, SignJWT } from 'jose';

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

export const ID_PATTERN = /^[A-Za-z0-9_-]{1,128}$/;
export const CODE_PATTERN = /^\d{6}$/;

const enc = encodeURIComponent;

// Cache token OAuth per isolate: dipakai ulang sampai 5 menit sebelum kedaluwarsa.
const TOKEN_REFRESH_MARGIN_MS = 5 * 60 * 1000;
const tokenCache = new Map<string, { token: string; exp: number }>();

export function clearTokenCache(): void {
  tokenCache.clear();
}

export async function getAccessToken(
  sa: ServiceAccount,
  fetcher: typeof fetch = (input, init) => fetch(input, init),
  nowMs: number = Date.now(),
): Promise<string> {
  const cached = tokenCache.get(sa.client_email);
  if (cached && cached.exp - TOKEN_REFRESH_MARGIN_MS > nowMs) return cached.token;

  const privateKey = await importPKCS8(sa.private_key, 'RS256');
  const now = Math.floor(nowMs / 1000);
  const jwt = await new SignJWT({
    iss: sa.client_email,
    sub: sa.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    scope: 'https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const res = await fetcher('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) {
    throw new Error(`getAccessToken_failed_${res.status}`);
  }
  const json = (await res.json()) as { access_token?: string; expires_in?: number };
  if (!json.access_token) throw new Error('getAccessToken_empty');
  tokenCache.set(sa.client_email, {
    token: json.access_token,
    exp: nowMs + (json.expires_in ?? 3600) * 1000,
  });
  return json.access_token;
}

// Prasyarat gagal: 409/412, atau 400 dengan FAILED_PRECONDITION di badan.
async function isPreconditionFailure(res: Response): Promise<boolean> {
  if (res.status === 409 || res.status === 412) return true;
  if (res.status !== 400) return false;
  const text = await res.text().catch(() => '');
  return text.includes('FAILED_PRECONDITION');
}

export interface PairingCodeDoc {
  familyId: string;
  childId: string;
  expiresAt: string; // ISO 8601
  usedAt: string | null; // ISO 8601 or null
  updateTime?: string;
}

export class FirestoreClient {
  constructor(
    private readonly projectId: string,
    private readonly tokenGetter: () => Promise<string>,
    private readonly fetcher: typeof fetch = (input, init) => fetch(input, init),
  ) {}

  private get baseUrl(): string {
    return `https://firestore.googleapis.com/v1/projects/${enc(this.projectId)}/databases/(default)/documents`;
  }

  private get docPrefix(): string {
    return `projects/${this.projectId}/databases/(default)/documents`;
  }

  private async authHeaders(extra: Record<string, string> = {}): Promise<Record<string, string>> {
    const token = await this.tokenGetter();
    return { Authorization: `Bearer ${token}`, ...extra };
  }

  async getPairingCode(code: string): Promise<PairingCodeDoc | null> {
    const url = `${this.baseUrl}/pairingCodes/${enc(code)}`;
    const res = await this.fetcher(url, { headers: await this.authHeaders() });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`getPairingCode_failed_${res.status}`);
    const doc = (await res.json()) as {
      fields?: Record<string, { stringValue?: string; nullValue?: null }>;
      updateTime?: string;
    };
    const fields = doc.fields ?? {};
    return {
      familyId: fields.familyId?.stringValue ?? '',
      childId: fields.childId?.stringValue ?? '',
      expiresAt: fields.expiresAt?.stringValue ?? '',
      usedAt: fields.usedAt?.stringValue ?? null,
      updateTime: doc.updateTime,
    };
  }

  async checkChildExists(familyId: string, childId: string): Promise<boolean> {
    const url = `${this.baseUrl}/families/${enc(familyId)}/children/${enc(childId)}?mask.fieldPaths=id`;
    const res = await this.fetcher(url, { headers: await this.authHeaders() });
    if (res.status === 404) return false;
    if (!res.ok) throw new Error(`checkChildExists_failed_${res.status}`);
    return true;
  }

  async checkFamilyMember(familyId: string, uid: string): Promise<boolean> {
    if (uid === familyId) return true;
    const url = `${this.baseUrl}/families/${enc(familyId)}/devices/${enc(uid)}?mask.fieldPaths=role`;
    const res = await this.fetcher(url, { headers: await this.authHeaders() });
    if (res.status === 404) return false;
    if (!res.ok) throw new Error(`checkFamilyMember_failed_${res.status}`);
    const doc = (await res.json()) as { fields?: Record<string, { stringValue?: string }> };
    const role = doc.fields?.role?.stringValue;
    return role === 'child' || role === 'caregiver';
  }

  async getNotification(
    familyId: string,
    notificationId: string,
  ): Promise<{ type: string; text: string; at?: string } | null> {
    const url = `${this.baseUrl}/families/${enc(familyId)}/notifications/${enc(notificationId)}`;
    const res = await this.fetcher(url, { headers: await this.authHeaders() });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`getNotification_failed_${res.status}`);
    const doc = (await res.json()) as {
      fields?: Record<string, { stringValue?: string; timestampValue?: string }>;
    };
    const fields = doc.fields ?? {};
    return {
      type: fields.type?.stringValue ?? '',
      text: fields.text?.stringValue ?? '',
      at: fields.at?.stringValue ?? fields.at?.timestampValue,
    };
  }

  async getDevices(
    familyId: string,
  ): Promise<Array<{ uid: string; fcmToken?: string; role?: string }>> {
    const url =
      `${this.baseUrl}/families/${enc(familyId)}/devices` +
      '?mask.fieldPaths=fcmToken&mask.fieldPaths=role&pageSize=100';
    const res = await this.fetcher(url, { headers: await this.authHeaders() });
    if (res.status === 404) return [];
    if (!res.ok) throw new Error(`getDevices_failed_${res.status}`);
    const json = (await res.json()) as {
      documents?: Array<{
        name: string;
        fields?: Record<string, { stringValue?: string }>;
      }>;
    };
    const docs = json.documents ?? [];
    return docs.map((doc) => {
      const parts = doc.name.split('/');
      const uid = parts[parts.length - 1];
      const fields = doc.fields ?? {};
      return {
        uid,
        fcmToken: fields.fcmToken?.stringValue,
        role: fields.role?.stringValue,
      };
    });
  }

  // Menghapus fcmToken. Bila expectedToken diberikan, hanya dihapus bila token
  // di dokumen masih sama (dicek lewat prasyarat updateTime).
  async clearFcmToken(familyId: string, uid: string, expectedToken?: string): Promise<void> {
    const docUrl = `${this.baseUrl}/families/${enc(familyId)}/devices/${enc(uid)}`;
    let precondition = 'currentDocument.exists=true';
    if (expectedToken !== undefined) {
      const getRes = await this.fetcher(`${docUrl}?mask.fieldPaths=fcmToken`, {
        headers: await this.authHeaders(),
      });
      if (getRes.status === 404) return;
      if (!getRes.ok) throw new Error(`clearFcmToken_get_failed_${getRes.status}`);
      const doc = (await getRes.json()) as {
        fields?: Record<string, { stringValue?: string }>;
        updateTime?: string;
      };
      if (doc.fields?.fcmToken?.stringValue !== expectedToken) return;
      if (doc.updateTime) {
        precondition = `currentDocument.updateTime=${enc(doc.updateTime)}`;
      }
    }
    const res = await this.fetcher(
      `${docUrl}?updateMask.fieldPaths=fcmToken&${precondition}`,
      {
        method: 'PATCH',
        headers: await this.authHeaders({ 'Content-Type': 'application/json' }),
        body: JSON.stringify({ fields: { fcmToken: { nullValue: null } } }),
      },
    );
    if (res.ok) return;
    // Dokumen hilang atau berubah di antara baca dan tulis: tidak ada yang perlu dihapus.
    if (res.status === 404 || (await isPreconditionFailure(res))) return;
    throw new Error(`clearFcmToken_failed_${res.status}`);
  }

  // Menulis kode baru dengan prasyarat belum ada. false = bentrok dengan kode lain.
  async savePairingCode(code: string, data: PairingCodeDoc): Promise<boolean> {
    const url = `${this.baseUrl}/pairingCodes/${enc(code)}?currentDocument.exists=false`;
    const res = await this.fetcher(url, {
      method: 'PATCH',
      headers: await this.authHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify({
        fields: {
          familyId: { stringValue: data.familyId },
          childId: { stringValue: data.childId },
          expiresAt: { stringValue: data.expiresAt },
          usedAt: { nullValue: null },
        },
      }),
    });
    if (res.ok) return true;
    if (await isPreconditionFailure(res)) return false;
    throw new Error(`savePairingCode_failed_${res.status}`);
  }

  async claimPairingCodeAndRegisterDevice(params: {
    code: string;
    familyId: string;
    childId: string;
    childUid: string;
    usedAt: string;
    expiresAt: string;
    updateTime: string;
  }): Promise<boolean> {
    // Pemilik keluarga tidak boleh didaftarkan sebagai HP anak.
    if (params.childUid === params.familyId) return false;
    if (!params.updateTime) return false;
    const commitUrl = `${this.baseUrl}:commit`;
    const body = {
      writes: [
        {
          update: {
            name: `${this.docPrefix}/pairingCodes/${enc(params.code)}`,
            fields: {
              familyId: { stringValue: params.familyId },
              childId: { stringValue: params.childId },
              expiresAt: { stringValue: params.expiresAt },
              usedAt: { stringValue: params.usedAt },
            },
          },
          // Prasyarat updateTime: kode hanya bisa dipakai sekali. Bila kode
          // berubah di antara baca dan commit, Firestore menolak.
          currentDocument: { updateTime: params.updateTime },
        },
        {
          update: {
            name: `${this.docPrefix}/families/${enc(params.familyId)}/devices/${enc(params.childUid)}`,
            fields: {
              role: { stringValue: 'child' },
              childId: { stringValue: params.childId },
              createdAt: { stringValue: params.usedAt },
            },
          },
        },
      ],
    };
    const res = await this.fetcher(commitUrl, {
      method: 'POST',
      headers: await this.authHeaders({ 'Content-Type': 'application/json' }),
      body: JSON.stringify(body),
    });
    if (res.ok) return true;
    if (await isPreconditionFailure(res)) return false;
    throw new Error(`commit_failed_${res.status}`);
  }
}

export async function sendFcmMessage(
  projectId: string,
  tokenGetter: () => Promise<string>,
  fcmToken: string,
  title: string,
  body: string,
  fetcher: typeof fetch = (input, init) => fetch(input, init),
): Promise<{ ok: boolean; unregistered: boolean }> {
  const accessToken = await tokenGetter();
  const url = `https://fcm.googleapis.com/v1/projects/${enc(projectId)}/messages:send`;
  const res = await fetcher(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        android: { priority: 'high' },
      },
    }),
  });

  if (res.ok) return { ok: true, unregistered: false };

  // Hanya UNREGISTERED dari badan JSON yang berarti token mati. 404 polos
  // (mis. proyek salah konfigurasi) tidak boleh menghapus token.
  let unregistered = false;
  try {
    const json = (await res.json()) as {
      error?: { status?: string; details?: Array<{ errorCode?: string }> };
    };
    unregistered =
      json.error?.status === 'UNREGISTERED' ||
      (json.error?.details ?? []).some((d) => d?.errorCode === 'UNREGISTERED');
  } catch {
    unregistered = false;
  }
  return { ok: false, unregistered };
}
