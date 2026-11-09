import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'autiplan-bd927',
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('Firestore Rules', () => {
  const familyId = 'caregiver-1';
  const childId = 'child-1';
  const childUid = 'child-device-uid';
  const otherFamilyId = 'caregiver-2';

  async function setupChildDevice() {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await db.doc(`families/${familyId}/devices/${childUid}`).set({
        role: 'child',
        childId: childId,
      });
      await db.doc(`families/${familyId}/children/${childId}`).set({
        id: childId,
        name: 'Rafi',
        fullName: 'Rafi Ahmad',
        age: 12,
        theme: 'lautTenang',
        likes: ['sepeda'],
        avoids: ['bising'],
      });
    });
  }

  test('orang asing tidak bisa membaca apa pun', async () => {
    const unauth = testEnv.unauthenticatedContext().firestore();
    await assertFails(unauth.doc(`families/${familyId}`).get());
    await assertFails(unauth.collection(`families/${familyId}/activities`).get());
    await assertFails(unauth.doc(`pairingCodes/123456`).get());
  });

  test('orang tua tidak bisa membaca atau menulis keluarga lain', async () => {
    const caregiver = testEnv.authenticatedContext(familyId).firestore();
    await assertFails(caregiver.doc(`families/${otherFamilyId}`).get());
    await assertFails(
      caregiver.doc(`families/${otherFamilyId}/activities/act-1`).set({
        title: 'Mandi',
      })
    );
  });

  test('anak tidak bisa membaca keluarga lain', async () => {
    await setupChildDevice();
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertFails(child.doc(`families/${otherFamilyId}`).get());
  });

  test('anak tidak bisa menulis activities', async () => {
    await setupChildDevice();
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertFails(
      child.doc(`families/${familyId}/activities/act-1`).set({
        title: 'Bermain',
      })
    );
  });

  test('anak tidak bisa mengubah title notice', async () => {
    await setupChildDevice();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`families/${familyId}/notices/notice-1`)
        .set({
          title: 'Awal',
          seenAt: null,
        });
    });
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertFails(
      child.doc(`families/${familyId}/notices/notice-1`).update({
        title: 'Diubah Anak',
      })
    );
  });

  test('anak bisa mengisi seenAt pada notice', async () => {
    await setupChildDevice();
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .firestore()
        .doc(`families/${familyId}/notices/notice-1`)
        .set({
          title: 'Awal',
          message: 'Pesan',
          seenAt: null,
        });
    });
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertSucceeds(
      child.doc(`families/${familyId}/notices/notice-1`).update({
        seenAt: '2026-11-09T10:00:00Z',
      })
    );
  });

  test('anak tidak bisa mengubah likes', async () => {
    await setupChildDevice();
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertFails(
      child.doc(`families/${familyId}/children/${childId}`).update({
        likes: ['suka baru'],
      })
    );
  });

  test('anak bisa mengubah theme miliknya', async () => {
    await setupChildDevice();
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertSucceeds(
      child.doc(`families/${familyId}/children/${childId}`).update({
        theme: 'padangHijau',
      })
    );
  });

  test('anak bisa membuat completion', async () => {
    await setupChildDevice();
    const child = testEnv.authenticatedContext(childUid).firestore();
    await assertSucceeds(
      child.doc(`families/${familyId}/completions/act-1_2026-11-09`).set({
        activityId: 'act-1',
        date: '2026-11-09',
        completedAt: '2026-11-09T10:00:00Z',
        onTime: true,
        stepsChecked: [true],
      })
    );
  });

  test('pairingCodes tertutup untuk semua klien', async () => {
    await setupChildDevice();
    const caregiver = testEnv.authenticatedContext(familyId).firestore();
    const child = testEnv.authenticatedContext(childUid).firestore();

    await assertFails(caregiver.doc('pairingCodes/123456').get());
    await assertFails(caregiver.doc('pairingCodes/123456').set({ familyId }));
    await assertFails(child.doc('pairingCodes/123456').get());
  });
});