import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/account_screen.dart';
import 'package:autiplan/features/caregiver/account_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

class FakeBackendApi implements BackendApi {
  int createCalls = 0;

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    createCalls += 1;
    return PairingCode(code: '654321', expiresAt: DateTime(2026, 5, 1, 16, 10));
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    return const ClaimedLink(familyId: 'fam', childId: 'child');
  }

  @override
  Future<void> notify(String familyId, String notificationId) async {}
}

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
        wrap(
          const AccountProfileCard(linkedChildName: 'Rafi'),
          linkedDevices: const [LinkedDevice(uid: 'u1', childId: 'child-1')],
        ),
      );
      expect(
        find.text('Pengasuh utama · Terhubung ke HP Rafi'),
        findsOneWidget,
      );
    });
  });

  group('Layar Akun', () {
    testWidgets('menampilkan baris Hubungkan dan Putuskan HP Rafi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrap(const CaregiverAccountScreen()));
      expect(find.text('Hubungkan HP Rafi'), findsOneWidget);
      expect(find.text('Putuskan HP Rafi'), findsOneWidget);
    });
  });
}
