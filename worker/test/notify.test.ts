import { describe, expect, test, vi } from 'vitest';
import { handleNotify } from '../src/notify.js';
import type { FirestoreClient } from '../src/firestore.js';

class FakeFirestoreClient {
  constructor(
    public member: boolean = true,
    public notification: { type: string; text: string; at?: string } | null = {
      type: 'changeSeen',
      text: 'Rafi melihat perubahan',
    },
    public devices: Array<{ uid: string; fcmToken?: string; role?: string }> = [
      { uid: 'caregiver-1', fcmToken: 'token-123', role: 'caregiver' },
    ],
  ) {}

  clearedTokens: Array<{ familyId: string; uid: string; expectedToken?: string }> = [];

  async checkFamilyMember(): Promise<boolean> {
    return this.member;
  }

  async getNotification(): Promise<{ type: string; text: string; at?: string } | null> {
    return this.notification;
  }

  async getDevices(): Promise<Array<{ uid: string; fcmToken?: string; role?: string }>> {
    return this.devices;
  }

  async clearFcmToken(familyId: string, uid: string, expectedToken?: string): Promise<void> {
    this.clearedTokens.push({ familyId, uid, expectedToken });
  }

  async getPairingCode() { return null; }
  async checkChildExists() { return true; }
  async savePairingCode() {}
  async claimPairingCodeAndRegisterDevice() { return true; }
}

describe('handleNotify', () => {
  test('mengambil teks dari dokumen Firestore dan mengabaikan isi permintaan', async () => {
    let sentPayload: any = null;
    const fetcher = async (_input: any, init: any) => {
      sentPayload = JSON.parse(init.body);
      return new Response(null, { status: 200 });
    };

    const db = new FakeFirestoreClient(true, { type: 'changeSeen', text: 'Teks dari DB' });
    const res = await handleNotify(
      'child-uid',
      { familyId: 'fam-1', notificationId: 'notif-1', text: 'Teks palsu di body' },
      db as unknown as FirestoreClient,
      'project-1',
      async () => 'access-token',
      fetcher,
    );

    expect(res.status).toBe(204);
    expect(sentPayload.message.notification.body).toBe('Teks dari DB');
  });

  test('tipe activityDone tidak mengirim apa pun dan membalas 204', async () => {
    let fetchCalled = false;
    const fetcher = async () => {
      fetchCalled = true;
      return new Response(null, { status: 200 });
    };

    const db = new FakeFirestoreClient(true, { type: 'activityDone', text: 'Selesai' });
    const res = await handleNotify(
      'child-uid',
      { familyId: 'fam-1', notificationId: 'notif-1' },
      db as unknown as FirestoreClient,
      'project-1',
      async () => 'access-token',
      fetcher,
    );

    expect(res.status).toBe(204);
    expect(fetchCalled).toBe(false);
  });

  test('uid di luar keluarga mendapat 403', async () => {
    const db = new FakeFirestoreClient(false, null, []);
    const res = await handleNotify(
      'stranger-uid',
      { familyId: 'fam-1', notificationId: 'notif-1' },
      db as unknown as FirestoreClient,
      'project-1',
      async () => 'access-token',
      async () => new Response(null, { status: 200 }),
    );

    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body).toEqual({ error: 'forbidden' });
  });

  test('token FCM UNREGISTERED dihapus dari dokumen perangkat', async () => {
    const fetcher = async () => {
      return new Response(JSON.stringify({ error: { status: 'UNREGISTERED' } }), {
        status: 404,
      });
    };

    const db = new FakeFirestoreClient(true, { type: 'changeSeen', text: 'Perubahan' }, [
      { uid: 'caregiver-1', fcmToken: 'bad-token', role: 'caregiver' },
    ]);

    const res = await handleNotify(
      'child-uid',
      { familyId: 'fam-1', notificationId: 'notif-1' },
      db as unknown as FirestoreClient,
      'project-1',
      async () => 'access-token',
      fetcher,
    );

    expect(res.status).toBe(204);
    expect(db.clearedTokens).toEqual([
      { familyId: 'fam-1', uid: 'caregiver-1', expectedToken: 'bad-token' },
    ]);
  });
});

// ---------------------------------------------------------------------------
// Perilaku yang diperketat
// ---------------------------------------------------------------------------

type Dev = { uid: string; fcmToken?: string; role?: string };

async function run(
  db: FakeFirestoreClient,
  fetcher: typeof fetch,
  body: Record<string, unknown> = { familyId: 'fam-1', notificationId: 'notif-1' },
  nowMs?: number,
  tokenGetter: () => Promise<string> = async () => 'access-token',
) {
  return handleNotify('child-uid', body, db as unknown as FirestoreClient, 'project-1', tokenGetter, fetcher, nowMs);
}

describe('handleNotify (diperketat)', () => {
  const ok = (async () => new Response('{}', { status: 200 })) as typeof fetch;

  test('dokumen notifikasi belum ada → 404 not_found (klien boleh mencoba lagi)', async () => {
    const res = await run(new FakeFirestoreClient(true, null), ok);
    expect(res.status).toBe(404);
    expect(await res.json()).toEqual({ error: 'not_found' });
  });

  test.each(['activityStarted', 'activityDone', 'lainnya', ''])(
    'tipe %s tidak diizinkan → 204 tanpa kirim',
    async (type) => {
      const fetcher = vi.fn(ok);
      const res = await run(new FakeFirestoreClient(true, { type, text: 'x' }), fetcher as typeof fetch);
      expect(res.status).toBe(204);
      expect(fetcher).not.toHaveBeenCalled();
    },
  );

  test('emergencyPressed dikirim', async () => {
    const fetcher = vi.fn(ok);
    await run(new FakeFirestoreClient(true, { type: 'emergencyPressed', text: 'Darurat' }), fetcher as typeof fetch);
    expect(fetcher).toHaveBeenCalledTimes(1);
  });

  test('satu perangkat gagal, perangkat lain tetap terkirim', async () => {
    const devices: Dev[] = [
      { uid: 'a', fcmToken: 'tok-a', role: 'caregiver' },
      { uid: 'b', fcmToken: 'tok-b', role: 'caregiver' },
      { uid: 'c', fcmToken: 'tok-c', role: 'caregiver' },
    ];
    const sent: string[] = [];
    const fetcher = (async (_u: any, init: any) => {
      const token = JSON.parse(init.body).message.token as string;
      if (token === 'tok-a') throw new Error('jaringan putus');
      sent.push(token);
      return new Response('{}', { status: 200 });
    }) as typeof fetch;
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const db = new FakeFirestoreClient(true, undefined, devices);
    const res = await run(db, fetcher);
    expect(res.status).toBe(204);
    expect(sent.sort()).toEqual(['tok-b', 'tok-c']);
    vi.restoreAllMocks();
  });

  test('perangkat anak, tanpa token, dan pemanggil sendiri dilewati', async () => {
    const devices: Dev[] = [
      { uid: 'kid', fcmToken: 'tok-kid', role: 'child' },
      { uid: 'x', role: 'caregiver' },
      { uid: 'child-uid', fcmToken: 'tok-self', role: 'caregiver' },
      { uid: 'ok', fcmToken: 'tok-ok', role: 'caregiver' },
    ];
    const sent: string[] = [];
    const fetcher = (async (_u: any, init: any) => {
      sent.push(JSON.parse(init.body).message.token);
      return new Response('{}', { status: 200 });
    }) as typeof fetch;
    await run(new FakeFirestoreClient(true, undefined, devices), fetcher);
    expect(sent).toEqual(['tok-ok']);
  });

  test('token OAuth diambil sekali walau perangkat banyak', async () => {
    const devices: Dev[] = [
      { uid: 'a', fcmToken: 'tok-a', role: 'caregiver' },
      { uid: 'b', fcmToken: 'tok-b', role: 'caregiver' },
    ];
    const getter = vi.fn(async () => 'access-token');
    await run(new FakeFirestoreClient(true, undefined, devices), ok, undefined, undefined, getter);
    expect(getter).toHaveBeenCalledTimes(1);
  });

  test('404 salah konfigurasi (bukan UNREGISTERED) tidak menghapus token', async () => {
    const fetcher = (async () =>
      new Response(JSON.stringify({ error: { status: 'NOT_FOUND' } }), { status: 404 })) as typeof fetch;
    vi.spyOn(console, 'error').mockImplementation(() => {});
    const db = new FakeFirestoreClient();
    const res = await run(db, fetcher);
    expect(res.status).toBe(204);
    expect(db.clearedTokens).toEqual([]);
    vi.restoreAllMocks();
  });

  test('UNREGISTERED dari details[].errorCode menghapus token', async () => {
    const fetcher = (async () =>
      new Response(
        JSON.stringify({ error: { status: 'NOT_FOUND', details: [{ errorCode: 'UNREGISTERED' }] } }),
        { status: 404 },
      )) as typeof fetch;
    const db = new FakeFirestoreClient();
    await run(db, fetcher);
    expect(db.clearedTokens).toHaveLength(1);
  });

  test('notifikasi lebih tua dari 10 menit (berzona waktu) diabaikan; tanpa zona tetap dikirim', async () => {
    const now = Date.UTC(2026, 10, 10, 12, 0, 0);
    const fetcher = vi.fn(ok);
    const old = new Date(now - 11 * 60 * 1000).toISOString();
    const fresh = new Date(now - 5 * 60 * 1000).toISOString();
    await run(new FakeFirestoreClient(true, { type: 'changeSeen', text: 'x', at: old }), fetcher as typeof fetch, undefined, now);
    expect(fetcher).not.toHaveBeenCalled();
    await run(new FakeFirestoreClient(true, { type: 'changeSeen', text: 'x', at: fresh }), fetcher as typeof fetch, undefined, now);
    expect(fetcher).toHaveBeenCalledTimes(1);
    await run(new FakeFirestoreClient(true, { type: 'changeSeen', text: 'x', at: '2026-01-01T00:00:00.000' }), fetcher as typeof fetch, undefined, now);
    expect(fetcher).toHaveBeenCalledTimes(2);
  });

  test('parameter tidak valid → 400', async () => {
    for (const body of [{}, { familyId: 'f' }, { familyId: '../a', notificationId: 'n' }, { familyId: 1, notificationId: 'n' }]) {
      const res = await run(new FakeFirestoreClient(), ok, body as Record<string, unknown>);
      expect(res.status).toBe(400);
    }
  });
});
