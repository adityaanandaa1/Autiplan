export interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

export async function getAccessToken(sa: ServiceAccount, fetcher: typeof fetch = fetch): Promise<string> {
  const { importPKCS8, SignJWT } = await import('jose');
  const privateKey = await importPKCS8(sa.private_key, 'RS256');
  const now = Math.floor(Date.now() / 1000);
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
  const json = (await res.json()) as { access_token: string };
  return json.access_token;
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
    private readonly fetcher: typeof fetch = fetch,
  ) {}

  private get baseUrl(): string {
    return `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents`;
  }

  async getPairingCode(code: string): Promise<PairingCodeDoc | null> {
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/pairingCodes/${code}`;
    const res = await this.fetcher(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
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
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/families/${familyId}/children/${childId}`;
    const res = await this.fetcher(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return res.status === 200;
  }

  async checkFamilyMember(familyId: string, uid: string): Promise<boolean> {
    if (uid === familyId) return true;
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/families/${familyId}/devices/${uid}`;
    const res = await this.fetcher(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return res.status === 200;
  }

  async getNotification(
    familyId: string,
    notificationId: string,
  ): Promise<{ type: string; text: string } | null> {
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/families/${familyId}/notifications/${notificationId}`;
    const res = await this.fetcher(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`getNotification_failed_${res.status}`);
    const doc = (await res.json()) as {
      fields?: Record<string, { stringValue?: string }>;
    };
    const fields = doc.fields ?? {};
    return {
      type: fields.type?.stringValue ?? '',
      text: fields.text?.stringValue ?? '',
    };
  }

  async getDevices(
    familyId: string,
  ): Promise<Array<{ uid: string; fcmToken?: string; role?: string }>> {
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/families/${familyId}/devices`;
    const res = await this.fetcher(url, {
      headers: { Authorization: `Bearer ${token}` },
    });
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

  async clearFcmToken(familyId: string, uid: string): Promise<void> {
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/families/${familyId}/devices/${uid}?updateMask.fieldPaths=fcmToken`;
    await this.fetcher(url, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          fcmToken: { nullValue: null },
        },
      }),
    });
  }

  async savePairingCode(code: string, data: PairingCodeDoc): Promise<void> {
    const token = await this.tokenGetter();
    const url = `${this.baseUrl}/pairingCodes/${code}`;
    const res = await this.fetcher(url, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          familyId: { stringValue: data.familyId },
          childId: { stringValue: data.childId },
          expiresAt: { stringValue: data.expiresAt },
          usedAt: { nullValue: null },
        },
      }),
    });
    if (!res.ok) throw new Error(`savePairingCode_failed_${res.status}`);
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
    const token = await this.tokenGetter();
    const commitUrl = `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents:commit`;
    const body = {
      writes: [
        {
          update: {
            name: `projects/${this.projectId}/databases/(default)/documents/pairingCodes/${params.code}`,
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
            name: `projects/${this.projectId}/databases/(default)/documents/families/${params.familyId}/devices/${params.childUid}`,
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
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });
    if (res.status === 409 || res.status === 412) {
      // Aborted / precondition failed (code used simultaneously or changed)
      return false;
    }
    if (!res.ok) throw new Error(`commit_failed_${res.status}`);
    return true;
  }
}

export async function sendFcmMessage(
  projectId: string,
  tokenGetter: () => Promise<string>,
  fcmToken: string,
  title: string,
  body: string,
  fetcher: typeof fetch = fetch,
): Promise<{ ok: boolean; unregistered: boolean }> {
  const accessToken = await tokenGetter();
  const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const res = await fetcher(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: {
          title,
          body,
        },
      },
    }),
  });

  if (res.status === 200) {
    return { ok: true, unregistered: false };
  }

  const text = await res.text();
  const isUnregistered =
    res.status === 404 ||
    res.status === 410 ||
    text.includes('UNREGISTERED') ||
    text.includes('NOT_FOUND') ||
    text.includes('registration-token-not-registered');

  return { ok: false, unregistered: isUnregistered };
}
