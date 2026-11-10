import { beforeEach, describe, expect, test } from 'vitest';
import { generateKeyPairSync } from 'node:crypto';
import {
  clearTokenCache,
  FirestoreClient,
  getAccessToken,
  sendFcmMessage,
} from '../src/firestore.js';

interface Call {
  url: string;
  init?: RequestInit;
}

function makeClient(responder: (call: Call) => Response | Promise<Response>) {
  const calls: Call[] = [];
  const fetcher = (async (input: RequestInfo | URL, init?: RequestInit) => {
    const call = { url: String(input), init };
    calls.push(call);
    return responder(call);
  }) as typeof fetch;
  const client = new FirestoreClient('proj', async () => 'tok', fetcher);
  return { client, calls, fetcher };
}

const jsonRes = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status });

const claimParams = {
  code: '123456',
  familyId: 'fam',
  childId: 'kid',
  childUid: 'child-uid',
  usedAt: '2026-11-10T12:00:00.000Z',
  expiresAt: '2026-11-10T12:10:00.000Z',
  updateTime: '2026-11-10T11:59:00Z',
};

describe('FirestoreClient: URL dan body', () => {
  test('segmen path di-encode dan header Authorization dikirim', async () => {
    const { client, calls } = makeClient(() => new Response(null, { status: 404 }));
    await client.getPairingCode('12/34');
    await client.checkChildExists('fam/../x', 'kid?a=1');
    expect(calls[0].url).toContain('/pairingCodes/12%2F34');
    expect(calls[1].url).toContain('/families/fam%2F..%2Fx/children/kid%3Fa%3D1');
    expect((calls[0].init?.headers as Record<string, string>).Authorization).toBe('Bearer tok');
  });

  test('getDevices memakai mask fcmToken dan role', async () => {
    const { client, calls } = makeClient(() =>
      jsonRes(200, {
        documents: [{ name: 'projects/p/databases/(default)/documents/families/f/devices/u1', fields: { role: { stringValue: 'caregiver' }, fcmToken: { stringValue: 't' } } }],
      }),
    );
    const devices = await client.getDevices('f');
    expect(devices).toEqual([{ uid: 'u1', fcmToken: 't', role: 'caregiver' }]);
    expect(calls[0].url).toContain('mask.fieldPaths=fcmToken');
    expect(calls[0].url).toContain('mask.fieldPaths=role');
  });

  test('checkFamilyMember hanya menerima role child atau caregiver', async () => {
    const roles: Record<string, number> = {};
    for (const role of ['child', 'caregiver', 'tamu']) {
      const { client } = makeClient(() => jsonRes(200, { fields: { role: { stringValue: role } } }));
      roles[role] = (await client.checkFamilyMember('fam', 'uid')) ? 1 : 0;
    }
    expect(roles).toEqual({ child: 1, caregiver: 1, tamu: 0 });
    const { client: none } = makeClient(() => new Response(null, { status: 404 }));
    expect(await none.checkFamilyMember('fam', 'uid')).toBe(false);
    expect(await none.checkFamilyMember('fam', 'fam')).toBe(true);
  });

  test('getNotification mengembalikan type, text, at', async () => {
    const { client } = makeClient(() =>
      jsonRes(200, { fields: { type: { stringValue: 'changeSeen' }, text: { stringValue: 'Hai' }, at: { stringValue: '2026-11-10T00:00:00Z' } } }),
    );
    expect(await client.getNotification('f', 'n')).toEqual({ type: 'changeSeen', text: 'Hai', at: '2026-11-10T00:00:00Z' });
  });
});

describe('FirestoreClient: clearFcmToken', () => {
  test('tanpa expectedToken: PATCH dengan exists=true dan cek res.ok', async () => {
    const { client, calls } = makeClient(() => new Response('{}', { status: 200 }));
    await client.clearFcmToken('fam', 'u1');
    expect(calls).toHaveLength(1);
    expect(calls[0].init?.method).toBe('PATCH');
    expect(calls[0].url).toContain('updateMask.fieldPaths=fcmToken');
    expect(calls[0].url).toContain('currentDocument.exists=true');
  });

  test('galat server dilempar', async () => {
    const { client } = makeClient(() => new Response('x', { status: 500 }));
    await expect(client.clearFcmToken('fam', 'u1')).rejects.toThrow();
  });

  test('token sudah berganti: tidak ada PATCH', async () => {
    const { client, calls } = makeClient(() =>
      jsonRes(200, { fields: { fcmToken: { stringValue: 'token-baru' } }, updateTime: 'T' }),
    );
    await client.clearFcmToken('fam', 'u1', 'token-lama');
    expect(calls).toHaveLength(1);
    expect(calls[0].init?.method).toBeUndefined();
  });

  test('token masih sama: PATCH dengan prasyarat updateTime', async () => {
    const { client, calls } = makeClient((c) =>
      c.init?.method === 'PATCH'
        ? new Response('{}', { status: 200 })
        : jsonRes(200, { fields: { fcmToken: { stringValue: 'sama' } }, updateTime: '2026-11-10T01:02:03.5Z' }),
    );
    await client.clearFcmToken('fam', 'u1', 'sama');
    expect(calls).toHaveLength(2);
    expect(calls[1].url).toContain('currentDocument.updateTime=2026-11-10T01%3A02%3A03.5Z');
  });
});

describe('FirestoreClient: savePairingCode', () => {
  const data = { familyId: 'f', childId: 'c', expiresAt: 'x', usedAt: null };

  test('menulis dengan prasyarat exists=false', async () => {
    const { client, calls } = makeClient(() => new Response('{}', { status: 200 }));
    expect(await client.savePairingCode('123456', data)).toBe(true);
    expect(calls[0].url).toContain('currentDocument.exists=false');
  });

  test.each([
    [409, '{}'],
    [412, '{}'],
    [400, '{"error":{"status":"FAILED_PRECONDITION"}}'],
  ])('status %i berarti bentrok → false', async (status, body) => {
    const { client } = makeClient(() => new Response(body, { status }));
    expect(await client.savePairingCode('123456', data)).toBe(false);
  });

  test('400 tanpa FAILED_PRECONDITION dan 500 dilempar', async () => {
    const bad = makeClient(() => new Response('{"error":{"status":"INVALID_ARGUMENT"}}', { status: 400 }));
    await expect(bad.client.savePairingCode('123456', data)).rejects.toThrow();
    const err = makeClient(() => new Response('', { status: 500 }));
    await expect(err.client.savePairingCode('123456', data)).rejects.toThrow();
  });
});

describe('FirestoreClient: claimPairingCodeAndRegisterDevice', () => {
  test('commit memuat dua tulisan, nama ter-encode, dan prasyarat updateTime', async () => {
    const { client, calls } = makeClient(() => new Response('{}', { status: 200 }));
    expect(await client.claimPairingCodeAndRegisterDevice({ ...claimParams, childUid: 'a/b' })).toBe(true);
    expect(calls[0].url).toMatch(/documents:commit$/);
    const body = JSON.parse(String(calls[0].init?.body));
    expect(body.writes[0].currentDocument).toEqual({ updateTime: claimParams.updateTime });
    expect(body.writes[0].update.name).toContain('/pairingCodes/123456');
    expect(body.writes[1].update.name).toContain('/devices/a%2Fb');
    expect(body.writes[1].update.fields.role.stringValue).toBe('child');
  });

  test.each([
    [409, '{}'],
    [412, '{}'],
    [400, '{"error":{"status":"FAILED_PRECONDITION","message":"..."}}'],
  ])('klaim kedua (status %i) → false, bukan galat', async (status, body) => {
    const { client } = makeClient(() => new Response(body, { status }));
    expect(await client.claimPairingCodeAndRegisterDevice(claimParams)).toBe(false);
  });

  test('galat lain (500) dilempar', async () => {
    const { client } = makeClient(() => new Response('', { status: 500 }));
    await expect(client.claimPairingCodeAndRegisterDevice(claimParams)).rejects.toThrow();
  });

  test('uid sama dengan familyId ditolak tanpa memanggil Firestore', async () => {
    const { client, calls } = makeClient(() => new Response('{}', { status: 200 }));
    expect(await client.claimPairingCodeAndRegisterDevice({ ...claimParams, childUid: 'fam' })).toBe(false);
    expect(calls).toHaveLength(0);
  });
});

describe('sendFcmMessage', () => {
  const send = (res: Response) =>
    sendFcmMessage('proj', async () => 'tok', 'fcm-token', 'AutiPlan', 'isi', (async () => res) as typeof fetch);

  test('payload memuat android.priority high', async () => {
    let sent: any;
    await sendFcmMessage('proj', async () => 'tok', 'fcm-token', 'T', 'B', (async (_u: any, init: any) => {
      sent = JSON.parse(init.body);
      return new Response('{}', { status: 200 });
    }) as typeof fetch);
    expect(sent.message.android.priority).toBe('high');
    expect(sent.message.token).toBe('fcm-token');
  });

  test('UNREGISTERED dari details[].errorCode dikenali', async () => {
    const r = await send(
      jsonRes(404, { error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } }),
    );
    expect(r).toEqual({ ok: false, unregistered: true });
  });

  test('UNREGISTERED dari error.status dikenali', async () => {
    const r = await send(jsonRes(404, { error: { status: 'UNREGISTERED' } }));
    expect(r.unregistered).toBe(true);
  });

  test('404 NOT_FOUND polos (salah konfigurasi) tidak dianggap UNREGISTERED', async () => {
    const r = await send(jsonRes(404, { error: { status: 'NOT_FOUND', message: 'Project not found' } }));
    expect(r).toEqual({ ok: false, unregistered: false });
    expect((await send(new Response('bukan json', { status: 404 }))).unregistered).toBe(false);
  });

  test('200 sukses', async () => {
    expect(await send(new Response('{}', { status: 200 }))).toEqual({ ok: true, unregistered: false });
  });
});

describe('getAccessToken cache', () => {
  beforeEach(() => clearTokenCache());

  const pem = generateKeyPairSync('rsa', { modulusLength: 2048 })
    .privateKey.export({ type: 'pkcs8', format: 'pem' })
    .toString();
  const sa = { client_email: 'sa@x.iam', private_key: pem, project_id: 'proj' };

  test('dipakai ulang sampai 5 menit sebelum kedaluwarsa', async () => {
    let n = 0;
    const fetcher = (async () => {
      n += 1;
      return jsonRes(200, { access_token: `tok${n}`, expires_in: 3600 });
    }) as typeof fetch;
    const t0 = 1_000_000_000_000;
    expect(await getAccessToken(sa, fetcher, t0)).toBe('tok1');
    expect(await getAccessToken(sa, fetcher, t0 + 50 * 60 * 1000)).toBe('tok1');
    expect(await getAccessToken(sa, fetcher, t0 + 56 * 60 * 1000)).toBe('tok2');
    expect(n).toBe(2);
  });
});
