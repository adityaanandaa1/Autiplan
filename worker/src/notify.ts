import type { FirestoreClient } from './firestore.js';
import { ID_PATTERN, sendFcmMessage } from './firestore.js';

// Hanya dua jenis ini yang dikirim sebagai push (lihat DECISIONS 9 Nov, butir 5).
const PUSH_TYPES = new Set(['emergencyPressed', 'changeSeen']);
const MAX_AGE_MS = 10 * 60 * 1000;
const HAS_TIMEZONE = /(Z|[+-]\d{2}:?\d{2})$/i;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

// Waktu hanya dipercaya bila memuat zona waktu. Aplikasi menulis `at` dari
// DateTime lokal tanpa zona, dan itu tidak bisa dibandingkan dengan aman.
function isStale(at: string | undefined, nowMs: number): boolean {
  if (!at || !HAS_TIMEZONE.test(at)) return false;
  const t = Date.parse(at);
  return !Number.isNaN(t) && nowMs - t > MAX_AGE_MS;
}

export async function handleNotify(
  callerUid: string,
  body: Record<string, unknown>,
  firestore: FirestoreClient,
  projectId: string,
  tokenGetter: () => Promise<string>,
  fetcher: typeof fetch = (input, init) => fetch(input, init),
  nowMs: number = Date.now(),
): Promise<Response> {
  const { familyId, notificationId } = body;

  if (
    typeof familyId !== 'string' ||
    typeof notificationId !== 'string' ||
    !ID_PATTERN.test(familyId) ||
    !ID_PATTERN.test(notificationId)
  ) {
    return json(400, { error: 'invalid_parameters' });
  }

  const isMember = await firestore.checkFamilyMember(familyId, callerUid);
  if (!isMember) {
    return json(403, { error: 'forbidden' });
  }

  const notification = await firestore.getNotification(familyId, notificationId);
  if (!notification) {
    // Klien menulis dokumen lebih dulu; bila belum terlihat, klien boleh mencoba lagi.
    return json(404, { error: 'not_found' });
  }

  if (!PUSH_TYPES.has(notification.type)) {
    return new Response(null, { status: 204 });
  }
  if (isStale(notification.at, nowMs)) {
    return new Response(null, { status: 204 });
  }

  const targets = (await firestore.getDevices(familyId)).filter(
    (d) => d.fcmToken && d.uid !== callerUid && d.role === 'caregiver',
  );
  if (targets.length === 0) {
    return new Response(null, { status: 204 });
  }

  // Satu token OAuth untuk seluruh pengiriman.
  const accessToken = await tokenGetter();
  const getToken = async () => accessToken;

  const results = await Promise.allSettled(
    targets.map(async (device) => {
      const fcmToken = device.fcmToken as string;
      const result = await sendFcmMessage(
        projectId,
        getToken,
        fcmToken,
        'AutiPlan',
        notification.text,
        fetcher,
      );
      if (result.unregistered) {
        await firestore.clearFcmToken(familyId, device.uid, fcmToken);
      }
      if (!result.ok && !result.unregistered) {
        throw new Error('fcm_send_failed');
      }
    }),
  );

  results.forEach((r, i) => {
    if (r.status === 'rejected') {
      const msg = r.reason instanceof Error ? r.reason.message : 'unknown';
      console.error(`notify: perangkat ${targets[i].uid} gagal: ${msg}`);
    }
  });

  return new Response(null, { status: 204 });
}
