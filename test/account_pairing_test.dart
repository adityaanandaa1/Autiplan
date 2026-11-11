import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/account_screen.dart';
import 'package:autiplan/features/caregiver/account_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_backend_api.dart';
import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

void main() {
  late FakeBackendApi backend;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    backend = FakeBackendApi();
  });

  Widget wrap(Widget child, {List<LinkedDevice> linkedDevices = const []}) {
    return ProviderScope(
      overrides: [
        sessionProvider.overrideWithValue(testCaregiverSession),
        clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        backendApiProvider.overrideWithValue(backend),
        linkedDevicesProvider.overrideWith(
          (ref) => Stream.value(linkedDevices),
        ),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(
            InMemoryRepository(),
            buildFixtureState().copyWith(
              children: [
                buildFixtureState().children.first.copyWith(
                  id: 'child-1',
                  name: 'Rafi',
                ),
              ],
            ),
          ),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  void bigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('AccountProfileCard', () {
    testWidgets('belum terhubung', (tester) async {
      await tester.pumpWidget(
        wrap(const AccountProfileCard(), linkedDevices: const []),
      );
      expect(
        find.text('Pengasuh utama · Belum terhubung ke HP anak'),
        findsOneWidget,
      );
    });

    testWidgets('terhubung ke HP {anak}', (tester) async {
      await tester.pumpWidget(
        wrap(const AccountProfileCard(linkedChildName: 'Rafi')),
      );
      expect(
        find.text('Pengasuh utama · Terhubung ke HP Rafi'),
        findsOneWidget,
      );
    });
  });

  group('Layar Akun', () {
    testWidgets('Putuskan hanya tampil bila HP anak itu terhubung', (
      tester,
    ) async {
      bigView(tester);
      await tester.pumpWidget(wrap(const CaregiverAccountScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Hubungkan HP Rafi'), findsOneWidget);
      expect(find.text('Putuskan HP Rafi'), findsNothing);
      expect(
        find.text('Pengasuh utama · Belum terhubung ke HP anak'),
        findsOneWidget,
      );
    });

    testWidgets('terhubung: nama dipetakan dari childId, Putuskan tampil', (
      tester,
    ) async {
      bigView(tester);
      await tester.pumpWidget(
        wrap(
          const CaregiverAccountScreen(),
          linkedDevices: const [LinkedDevice(uid: 'u1', childId: 'child-1')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Putuskan HP Rafi'), findsOneWidget);
      expect(
        find.text('Pengasuh utama · Terhubung ke HP Rafi'),
        findsOneWidget,
      );
    });

    testWidgets('dua anak: setiap anak punya barisnya sendiri', (tester) async {
      bigView(tester);
      final rafi = buildFixtureState().children.first.copyWith(
        id: 'child-1',
        name: 'Rafi',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWithValue(testCaregiverSession),
            clockProvider.overrideWithValue(Clock(() => fixtureNow)),
            backendApiProvider.overrideWithValue(backend),
            linkedDevicesProvider.overrideWith(
              (ref) => Stream.value(const [
                LinkedDevice(uid: 'u1', childId: 'child-1'),
              ]),
            ),
            appStateProvider.overrideWith(
              (ref) => AppStateNotifier(
                InMemoryRepository(),
                buildFixtureState().copyWith(
                  children: [
                    rafi,
                    rafi.copyWith(id: 'child-2', name: 'Atalia'),
                  ],
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: CaregiverAccountScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('HP anak'), findsOneWidget);
      expect(find.text('Putuskan HP Rafi'), findsOneWidget);
      expect(find.text('Hubungkan HP Atalia'), findsOneWidget);
      expect(find.text('Hubungkan HP Rafi'), findsNothing);
      expect(find.text('Putuskan HP Atalia'), findsNothing);
    });

    testWidgets('perangkat anak lain: Putuskan HP Rafi tidak tampil', (
      tester,
    ) async {
      bigView(tester);
      await tester.pumpWidget(
        wrap(
          const CaregiverAccountScreen(),
          linkedDevices: const [LinkedDevice(uid: 'u1', childId: 'lain')],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Putuskan HP Rafi'), findsNothing);
    });
  });

  group('linkedChildNamesOf', () {
    final rafi = buildFixtureState().children.first.copyWith(
      id: 'c1',
      name: 'Rafi',
    );
    final atalia = rafi.copyWith(id: 'c2', name: 'Atalia');

    test('memetakan childId ke nama, bukan perangkat pertama saja', () {
      expect(
        linkedChildNamesOf(
          const [LinkedDevice(uid: 'u1', childId: 'c2')],
          [rafi, atalia],
        ),
        'Atalia',
      );
    });

    test('beberapa anak digabung; id tak dikenal diabaikan', () {
      expect(
        linkedChildNamesOf(
          const [
            LinkedDevice(uid: 'u1', childId: 'c1'),
            LinkedDevice(uid: 'u2', childId: 'c2'),
            LinkedDevice(uid: 'u3', childId: 'hilang'),
          ],
          [rafi, atalia],
        ),
        'Rafi, Atalia',
      );
    });

    test('kosong menghasilkan null', () {
      expect(linkedChildNamesOf(const [], [rafi]), isNull);
    });
  });
}
