import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/session/device_session.dart';
import 'package:autiplan/features/onboarding/link_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_service.dart';

class FakeBackendApi implements BackendApi {
  BackendFailure? nextFailure;
  ClaimedLink? nextLink;

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    return PairingCode(
      code: '123456',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    final f = nextFailure;
    if (f != null) throw BackendException(f);
    return nextLink ??
        const ClaimedLink(familyId: 'fam-test', childId: 'child-test');
  }

  @override
  Future<void> notify(String familyId, String notificationId) async {}
}

void main() {
  late FakeAuthService auth;
  late FakeBackendApi backend;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthService();
    backend = FakeBackendApi();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      backendApiProvider.overrideWithValue(backend),
      sessionProvider.overrideWithValue(const UnlinkedSession()),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('layar hubungkan menampilkan judul dan instruksi tenang', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const LinkDeviceScreen()));
    expect(find.text('Hubungkan HP'), findsOneWidget);
    expect(find.text('Minta kode 6 angka dari orang tua.'), findsOneWidget);
    expect(find.text('Hubungkan'), findsOneWidget);
  });

  group('Pesan galat kode', () {
    testWidgets('invalidCode → Kode belum cocok. Coba periksa lagi.', (
      tester,
    ) async {
      backend.nextFailure = BackendFailure.invalidCode;
      await tester.pumpWidget(wrap(const LinkDeviceScreen()));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Hubungkan'));
      await tester.pumpAndSettle();
      expect(find.text('Kode belum cocok. Coba periksa lagi.'), findsOneWidget);
    });

    testWidgets('expiredCode → Kode sudah tidak berlaku. Minta kode baru.', (
      tester,
    ) async {
      backend.nextFailure = BackendFailure.expiredCode;
      await tester.pumpWidget(wrap(const LinkDeviceScreen()));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Hubungkan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Kode sudah tidak berlaku. Minta kode baru.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'tooManyAttempts → Terlalu banyak percobaan. Coba lagi nanti.',
      (tester) async {
        backend.nextFailure = BackendFailure.tooManyAttempts;
        await tester.pumpWidget(wrap(const LinkDeviceScreen()));
        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.text('Hubungkan'));
        await tester.pumpAndSettle();
        expect(
          find.text('Terlalu banyak percobaan. Coba lagi nanti.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('offline → Belum ada internet. Coba lagi nanti.', (
      tester,
    ) async {
      backend.nextFailure = BackendFailure.offline;
      await tester.pumpWidget(wrap(const LinkDeviceScreen()));
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Hubungkan'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada internet. Coba lagi nanti.'), findsOneWidget);
    });
  });
}
