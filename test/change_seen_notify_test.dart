import 'dart:async';

import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/session/device_session.dart';
import 'package:autiplan/features/child/child_change_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';

class _Api implements BackendApi {
  _Api(this.onNotify);
  final Future<void> Function(String, String) onNotify;

  @override
  Future<PairingCode> createPairingCode(String childId) async =>
      throw UnimplementedError();

  @override
  Future<ClaimedLink> claimPairingCode(String code) async =>
      throw UnimplementedError();

  @override
  Future<void> notify(String familyId, String notificationId) =>
      onNotify(familyId, notificationId);
}

Future<ProviderContainer> _pump(WidgetTester tester, BackendApi backend) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/anak/perubahan',
    routes: [
      GoRoute(
        path: '/anak/perubahan',
        builder: (context, state) => const ChildChangeScreen(),
      ),
      GoRoute(
        path: '/anak',
        builder: (context, state) => const Scaffold(body: Text('Beranda anak')),
      ),
    ],
  );
  final base = buildFixtureState();
  const snap = ActivitySnapshot(
    shortTitle: 'Sepeda',
    title: 'Bersepeda',
    icon: ActivityIcon.sepeda,
    start: TimeOfDayLite(16, 0),
  );
  final initial = base.copyWith(
    notices: [
      ChangeNotice(
        id: 'notice-1',
        childId: 'child-rafi',
        activityId: 'act-x',
        before: snap,
        after: snap.copyWith(start: const TimeOfDayLite(17, 0)),
        message: 'Jadwal bergeser.',
        sentAt: fixtureNow,
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sessionProvider.overrideWithValue(
          const ChildSession(familyId: 'keluarga-tes', childId: 'child-rafi'),
        ),
        clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        backendApiProvider.overrideWithValue(backend),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(InMemoryRepository(), initial),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildParentTheme(childPalette: ChildPalette.lautTenang),
      ),
    ),
  );
  return ProviderScope.containerOf(
    tester.element(find.byType(ChildChangeScreen)),
  );
}

void main() {
  testWidgets('changeSeen memanggil notify dengan id notifikasi yang sama', (
    tester,
  ) async {
    final sent = <(String, String)>[];
    final container = await _pump(
      tester,
      _Api((f, n) async => sent.add((f, n))),
    );

    await tester.tap(find.text('Oke, aku mengerti'));
    await tester.pumpAndSettle();

    final seen = container
        .read(appStateProvider)
        .notifications
        .where((n) => n.type == NotificationType.changeSeen)
        .toList();
    expect(seen, hasLength(1));
    expect(sent, [('keluarga-tes', seen.single.id)]);
    expect(find.text('Beranda anak'), findsOneWidget);
  });

  testWidgets('tetap berpindah halaman bila notify melempar sinkron', (
    tester,
  ) async {
    await _pump(tester, _Api((_, _) => throw StateError('sinkron')));

    await tester.tap(find.text('Oke, aku mengerti'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda anak'), findsOneWidget);
  });

  testWidgets('tetap berpindah halaman bila notify menggantung', (
    tester,
  ) async {
    final never = Completer<void>();
    await _pump(tester, _Api((_, _) => never.future));

    await tester.tap(find.text('Oke, aku mengerti'));
    await tester.pumpAndSettle();

    expect(find.text('Beranda anak'), findsOneWidget);
  });

  testWidgets('tekan ganda hanya satu notifikasi dan satu push', (
    tester,
  ) async {
    final sent = <String>[];
    final container = await _pump(tester, _Api((_, n) async => sent.add(n)));

    await tester.tap(find.text('Oke, aku mengerti'));
    await tester.tap(find.text('Oke, aku mengerti'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final seen = container
        .read(appStateProvider)
        .notifications
        .where((n) => n.type == NotificationType.changeSeen);
    expect(seen, hasLength(1));
    expect(sent, hasLength(1));
    expect(find.text('Beranda anak'), findsOneWidget);
  });
}
