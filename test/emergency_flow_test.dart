import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/backend_api.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/child/child_emergency_screen.dart';
import 'package:autiplan/features/child/child_calling_screen.dart';
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
  final Future<void> Function() onNotify;

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    throw UnimplementedError();
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    throw UnimplementedError();
  }

  @override
  Future<void> notify(String familyId, String notificationId) async {
    await onNotify();
  }
}

void main() {
  testWidgets(
    'pada A-07 dengan BackendApi offline, launchUrl dipanggil SEBELUM notify, ke A-08, tanpa snackbar',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final calls = <String>[];

      final backend = TestBackendApi(() async {
        calls.add('notify');
        throw const BackendException(BackendFailure.offline);
      });

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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            sessionProvider.overrideWithValue(testChildSession),
            clockProvider.overrideWithValue(Clock(() => fixtureNow)),
            backendApiProvider.overrideWithValue(backend),
            phoneLauncherProvider.overrideWithValue((uri) async {
              calls.add('launch:${uri.toString()}');
            }),
            appStateProvider.overrideWith(
              (ref) => AppStateNotifier(
                InMemoryRepository(),
                buildFixtureState().copyWith(
                  settings: const Settings(emergencyNumber: '081234567890'),
                ),
              ),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.tap(find.text('Telepon Ibu Sari'));
      await tester.pumpAndSettle();

      expect(calls, ['launch:tel:081234567890', 'notify']);
      expect(find.text('Menelepon Ibu Sari…'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('internet'), findsNothing);
    },
  );
}
