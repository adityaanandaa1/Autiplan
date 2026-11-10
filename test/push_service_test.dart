import 'package:autiplan/data/push_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeUser extends Fake implements fa.User {
  @override
  String get uid => 'uid-1';
}

class _FakeAuth extends Fake implements fa.FirebaseAuth {
  @override
  fa.User? get currentUser => _FakeUser();
}

class _FakeSettings extends Fake implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
}

class _FakeMessaging extends Fake implements FirebaseMessaging {
  bool deleted = false;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async => _FakeSettings();

  @override
  Future<String?> getToken({
    String? serviceWorkerScriptPath,
    String? vapidKey,
  }) async => 'tok-1';

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<void> deleteToken() async => deleted = true;
}

void main() {
  test('register menyimpan token; unregister menghapusnya', () async {
    final db = FakeFirebaseFirestore();
    final messaging = _FakeMessaging();
    final service = FirebasePushService(
      messaging: messaging,
      firestore: db,
      auth: _FakeAuth(),
    );
    final doc = db.collection('families/fam/devices').doc('uid-1');

    await service.registerCaregiverDevice('fam');
    await service.registerCaregiverDevice('fam');
    expect((await doc.get()).data(), {
      'role': 'caregiver',
      'fcmToken': 'tok-1',
    });

    await service.unregister();
    expect((await doc.get()).data(), {'role': 'caregiver'});
    expect(messaging.deleted, isTrue);
  });

  test('unregister tanpa register tidak melempar', () async {
    final messaging = _FakeMessaging();
    final service = FirebasePushService(
      messaging: messaging,
      firestore: FakeFirebaseFirestore(),
      auth: _FakeAuth(),
    );
    await service.unregister();
    expect(messaging.deleted, isTrue);
  });
}
