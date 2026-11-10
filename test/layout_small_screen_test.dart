import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/account_screen.dart';
import 'package:autiplan/features/caregiver/home_screen.dart';
import 'package:autiplan/features/caregiver/schedule_screen.dart';
import 'package:autiplan/features/child/child_activity_screen.dart';
import 'package:autiplan/features/child/child_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

// Lebar 360 dp dan skala teks 1.3 (HANDOFF 14): tidak boleh ada overflow.
void main() {
  Future<void> pumpAt(WidgetTester tester, Widget screen) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await initializeDateFormatting('id_ID');
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWithValue(testCaregiverSession),
          sharedPreferencesProvider.overrideWithValue(prefs),
          linkedDevicesProvider.overrideWith((ref) => Stream.value(const [])),
          appStateProvider.overrideWith(
            (ref) =>
                AppStateNotifier(InMemoryRepository(), buildFixtureState()),
          ),
          clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        ],
        child: MaterialApp(
          theme: buildParentTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: screen,
        ),
      ),
    );
    await tester.pump();
  }

  final screens = <String, Widget>{
    'Beranda orang tua': const CaregiverHomeScreen(),
    'Jadwal orang tua': const CaregiverScheduleScreen(),
    'Akun orang tua': const CaregiverAccountScreen(),
    'Beranda anak': const ChildHomeScreen(),
    'Kegiatan anak': const ChildActivityScreen(
      activityId: 'rafi-sekolah-20260501',
    ),
  };
  screens.forEach((name, screen) {
    testWidgets('$name rapi di 360 dp dan skala teks 1.3', (tester) async {
      await pumpAt(tester, screen);
      expect(tester.takeException(), isNull);
    });
  });
}
