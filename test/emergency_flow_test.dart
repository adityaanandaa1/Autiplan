import 'dart:async';

import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/session/device_session.dart';
import 'package:autiplan/features/child/child_calling_screen.dart';
import 'package:autiplan/features/child/child_emergency_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

class TestBackendApi implements BackendApi {
  TestBackendApi(this.onNotify);
  final Future<void> Function(String familyId, String notificationId) onNotify;

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    throw UnimplementedError();
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    throw UnimplementedError();
  }

  @override
  Future<void> notify(String familyId, String notificationId) =>
      onNotify(familyId, notificationId);
}

const _rafiSession = ChildSession(
  familyId: 'keluarga-tes',
  childId: 'child-rafi',
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required BackendApi backend,
  required Future<void> Function(Uri) launcher,
  DeviceSession session = _rafiSession,
  String emergencyNumber = '081234567890',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/darurat',
    routes: [
      GoRoute(
        path: '/darurat',
        builder: (context, state) => const ChildEmergencyScreen(),
      ),
      GoRoute(
        path: '/anak/menelepon',
        builder: (context, state) => const ChildCallingScreen(),
      ),
    ],
  );
  final base = buildFixtureState();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sessionProvider.overrideWithValue(session),
        clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        backendApiProvider.overrideWithValue(backend),
        phoneLauncherProvider.overrideWithValue(launcher),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(
            InMemoryRepository(),
            base.copyWith(
              settings: base.settings.copyWith(
                emergencyNumber: emergencyNumber,
              ),
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildParentTheme(childPalette: ChildPalette.lautTenang),
      ),
    ),
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(ChildEmergencyScreen)),
  );
}

/// Notifikasi darurat BARU (fixture sudah memuat satu notifikasi lama).
List<CaregiverNotification> _emergencies(ProviderContainer c) => c
    .read(appStateProvider)
    .notifications
    .where(
      (n) => n.type == NotificationType.emergencyPressed && n.at == fixtureNow,
    )
    .toList();

void main() {
  testWidgets(
    'launchUrl dipanggil SEBELUM notify; notify offline tidak menahan A-08 '
    'dan tanpa snackbar',
    (tester) async {
      final calls = <String>[];
      await _pump(
        tester,
        backend: TestBackendApi((_, _) async {
          calls.add('notify');
          throw const BackendException(BackendFailure.offline);
        }),
        launcher: (uri) async => calls.add('launch:$uri'),
      );

      await tester.tap(find.text('Telepon Bu Sari'));
      await tester.pumpAndSettle();

      expect(calls, ['launch:tel:081234567890', 'notify']);
      expect(find.text('Menelepon Bu Sari…'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('internet'), findsNothing);
    },
  );

  testWidgets('notify yang menggantung tidak menahan navigasi ke A-08', (
    tester,
  ) async {
    final never = Completer<void>();
    await _pump(
      tester,
      backend: TestBackendApi((_, _) => never.future),
      launcher: (_) async {},
    );

    await tester.tap(find.text('Telepon Bu Sari'));
    await tester.pumpAndSettle();

    expect(find.text('Menelepon Bu Sari…'), findsOneWidget);
  });

  testWidgets('backend yang melempar sinkron tidak menahan navigasi', (
    tester,
  ) async {
    await _pump(
      tester,
      backend: TestBackendApi((_, _) => throw StateError('sinkron')),
      launcher: (_) async {},
    );

    await tester.tap(find.text('Telepon Bu Sari'));
    await tester.pumpAndSettle();

    expect(find.text('Menelepon Bu Sari…'), findsOneWidget);
  });

  testWidgets('notifikasi darurat tersimpan dan notify menerima id yang sama', (
    tester,
  ) async {
    final sent = <(String, String)>[];
    final container = await _pump(
      tester,
      backend: TestBackendApi((f, n) async => sent.add((f, n))),
      launcher: (_) async {},
    );

    await tester.tap(find.text('Telepon Bu Sari'));
    await tester.pumpAndSettle();

    final list = _emergencies(container);
    expect(list, hasLength(1));
    expect(list.single.text, 'Rafi menekan tombol bantuan');
    expect(list.single.read, isFalse);
    expect(sent, [('keluarga-tes', list.single.id)]);
  });

  testWidgets('tekan ganda hanya menghasilkan satu notifikasi dan satu push', (
    tester,
  ) async {
    final gate = Completer<void>();
    final sent = <String>[];
    final container = await _pump(
      tester,
      backend: TestBackendApi((_, n) async => sent.add(n)),
      launcher: (_) => gate.future,
    );

    await tester.tap(find.text('Telepon Bu Sari'));
    await tester.tap(find.text('Telepon Bu Sari'));
    gate.complete();
    await tester.pumpAndSettle();

    expect(_emergencies(container), hasLength(1));
    expect(sent, hasLength(1));
    expect(find.text('Menelepon Bu Sari…'), findsOneWidget);

    // Hanya satu halaman A-08 di tumpukan: kembali sekali sampai ke A-07.
    GoRouter.of(tester.element(find.byType(ChildCallingScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Telepon Bu Sari'), findsOneWidget);
  });

  testWidgets('sesi bukan ChildSession tidak memanggil notify', (tester) async {
    final sent = <String>[];
    final container = await _pump(
      tester,
      backend: TestBackendApi((_, n) async => sent.add(n)),
      launcher: (_) async {},
      session: testCaregiverSession,
    );

    await tester.tap(find.text('Telepon Bu Sari'));
    await tester.pumpAndSettle();

    expect(sent, isEmpty);
    expect(_emergencies(container), hasLength(1));
    expect(find.text('Menelepon Bu Sari…'), findsOneWidget);
  });

  testWidgets('nomor darurat kosong tidak memanggil launcher', (tester) async {
    var launched = 0;
    await _pump(
      tester,
      backend: TestBackendApi((_, _) async {}),
      launcher: (_) async => launched++,
      emergencyNumber: '',
    );

    await tester.tap(find.text('Telepon Bu Sari'));
    await tester.pumpAndSettle();

    expect(launched, 0);
    expect(find.text('Menelepon Bu Sari…'), findsOneWidget);
  });
}
