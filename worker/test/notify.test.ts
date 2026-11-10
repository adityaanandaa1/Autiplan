import { describe, expect, test } from 'vitest';
import { handleNotify } from '../src/notify.js';
import type { FirestoreClient } from '../src/firestore.js';

class FakeFirestoreClient {
  constructor(
    public member: boolean = true,
    public notification: { type: string; text: string } | null = {
      type: 'changeSeen',
      text: 'Rafi melihat perubahan',
    },
    public devices: Array<{ uid: string; fcmToken?: string; role?: string }> = [
      { uid: 'caregiver-1', fcmToken: 'token-123', role: 'caregiver' },
    ],
  ) {}

  clearedTokens: Array<{ familyId: string; uid: string }> = [];

  async checkFamilyMember(): Promise<boolean> {
    return this.member;
  }

  async getNotification(): Promise<{ type: string; text: string } | null> {
    return this.notification;
  }

  async getDevices(): Promise<Array<{ uid: string; fcmToken?: string; role?: string }>> {
    return this.devices;
  }

  async clearFcmToken(familyId: string, uid: string): Promise<void> {
    this.clearedTokens.push({ familyId, uid });
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

  test('tipe activityDone tidak mengirim apa pun', async () => {
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
    expect(db.clearedTokens).toEqual([{ familyId: 'fam-1', uid: 'caregiver-1' }]);
  });
});
