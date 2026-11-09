import 'package:autiplan/data/session/device_session.dart';
import 'package:autiplan/data/session/session_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_service.dart';

void main() {
  late SharedPreferences prefs;
  late FakeAuthService auth;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = FakeAuthService();
  });

  test('sesi awal adalah UnlinkedSession', () {
    final notifier = SessionNotifier(auth, prefs);
    expect(notifier.state, const UnlinkedSession());
  });

  test(
    'signUp dan signIn mengubah sesi ke CaregiverSession dan menyimpannya',
    () async {
      final notifier = SessionNotifier(auth, prefs);

      await notifier.signUp('ortu@example.com', 'password123');
      expect(notifier.state, isA<CaregiverSession>());
      final familyId = (notifier.state as CaregiverSession).familyId;

      // Buka notifier baru dengan prefs sama
      final restored = SessionNotifier(auth, prefs);
      expect(restored.state, CaregiverSession(familyId: familyId));
    },
  );

  test(
    'signOut mengembalikan ke UnlinkedSession dan menghapus simpanan',
    () async {
      final notifier = SessionNotifier(auth, prefs);
      await notifier.signIn('ortu@example.com', 'password123');
      await notifier.signOut();

      expect(notifier.state, const UnlinkedSession());

      final restored = SessionNotifier(auth, prefs);
      expect(restored.state, const UnlinkedSession());
    },
  );
}
