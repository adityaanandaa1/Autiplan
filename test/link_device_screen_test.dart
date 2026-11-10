import 'package:autiplan/data/auth_service.dart';
import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/session/device_session.dart';
import 'package:autiplan/data/session/session_notifier.dart';
import 'package:autiplan/features/onboarding/link_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_backend_api.dart';

class _AnonFailsAuth extends FakeAuthService {
  @override
  Future<String> signInAnonymously() async =>
      throw const AuthException('Belum bisa masuk. Coba lagi sebentar.');
}

void main() {
  late FakeAuthService auth;
  late FakeBackendApi backend;
  late SessionNotifier session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    auth = FakeAuthService();
    backend = FakeBackendApi();
    session = SessionNotifier(auth, prefs);
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      backendApiProvider.overrideWithValue(backend),
      sessionNotifierProvider.overrideWith((ref) => session),
    ],
    child: MaterialApp(home: child),
  );

  Future<void> submit(WidgetTester tester, [String code = '123456']) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.pump();
    await tester.tap(find.text('Hubungkan'));
    await tester.pumpAndSettle();
  }

  testWidgets('layar hubungkan menampilkan judul dan instruksi tenang', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LinkDeviceScreen()));
    expect(find.text('Hubungkan HP'), findsOneWidget);
    expect(find.text('Minta kode 6 angka dari orang tua.'), findsOneWidget);
    expect(find.text('Hubungkan'), findsOneWidget);
  });

  testWidgets('klaim sukses membentuk ChildSession dari hasil klaim', (
    tester,
  ) async {
    backend.nextLink = const ClaimedLink(familyId: 'fam-1', childId: 'anak-1');
    await tester.pumpWidget(wrap(const LinkDeviceScreen()));
    await submit(tester);
    expect(backend.claimedCodes, ['123456']);
    expect(
      session.state,
      const ChildSession(familyId: 'fam-1', childId: 'anak-1'),
    );
  });

  testWidgets('tombol nonaktif saat kolom kosong', (tester) async {
    await tester.pumpWidget(wrap(const LinkDeviceScreen()));
    await tester.tap(find.text('Hubungkan'));
    await tester.pumpAndSettle();
    expect(backend.claimCalls, 0);
    expect(session.state, const UnlinkedSession());
  });

  testWidgets('galat tak terduga: pesan unknown, tanpa sesi', (tester) async {
    backend.nextError = StateError('aneh');
    await tester.pumpWidget(wrap(const LinkDeviceScreen()));
    await submit(tester);
    expect(
      find.text('Belum bisa menghubungkan. Coba lagi sebentar.'),
      findsOneWidget,
    );
    expect(session.state, const UnlinkedSession());
  });

  testWidgets('AuthException ditampilkan apa adanya, klaim tidak dipanggil', (
    tester,
  ) async {
    auth = _AnonFailsAuth();
    final prefs = await SharedPreferences.getInstance();
    session = SessionNotifier(auth, prefs);
    await tester.pumpWidget(wrap(const LinkDeviceScreen()));
    await submit(tester);
    expect(find.text('Belum bisa masuk. Coba lagi sebentar.'), findsOneWidget);
    expect(backend.claimCalls, 0);
  });

  group('Pesan galat kode', () {
    const cases = {
      BackendFailure.invalidCode: 'Kode belum cocok. Coba periksa lagi.',
      BackendFailure.expiredCode: 'Kode sudah tidak berlaku. Minta kode baru.',
      BackendFailure.tooManyAttempts:
          'Terlalu banyak percobaan. Coba lagi nanti.',
      BackendFailure.offline: 'Belum ada internet. Coba lagi nanti.',
      BackendFailure.unknown: 'Belum bisa menghubungkan. Coba lagi sebentar.',
    };
    for (final entry in cases.entries) {
      testWidgets('${entry.key.name} menampilkan pesan tenang', (tester) async {
        backend.nextFailure = entry.key;
        await tester.pumpWidget(wrap(const LinkDeviceScreen()));
        await submit(tester);
        expect(find.text(entry.value), findsOneWidget);
      });
    }
  });
}
