import type { FirestoreClient } from './firestore.js';
import { sendFcmMessage } from './firestore.js';

export async function handleNotify(
  callerUid: string,
  body: { familyId?: string; notificationId?: string; text?: string },
  firestore: FirestoreClient,
  projectId: string,
  tokenGetter: () => Promise<string>,
  fetcher: typeof fetch = fetch,
): Promise<Response> {
  const familyId = body.familyId;
  const notificationId = body.notificationId;

  if (!familyId || !notificationId) {
    return new Response(JSON.stringify({ error: 'missing_parameters' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const isMember = await firestore.checkFamilyMember(familyId, callerUid);
  if (!isMember) {
    return new Response(JSON.stringify({ error: 'forbidden' }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const notification = await firestore.getNotification(familyId, notificationId);
  if (!notification) {
    return new Response(null, { status: 204 });
  }

  if (notification.type === 'activityDone') {
    return new Response(null, { status: 204 });
  }

  const devices = await firestore.getDevices(familyId);
  for (const device of devices) {
    if (device.fcmToken && device.uid !== callerUid && device.role !== 'child') {
      const result = await sendFcmMessage(
        projectId,
        tokenGetter,
        device.fcmToken,
        'AutiPlan',
        notification.text,
        fetcher,
      );
      if (result.unregistered) {
        await firestore.clearFcmToken(familyId, device.uid);
      }
    }
  }

  return new Response(null, { status: 204 });
}
