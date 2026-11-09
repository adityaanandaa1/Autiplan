import 'package:autiplan/core/clock.dart';
import 'support/in_memory_repository.dart';
import 'package:autiplan/core/widgets/initials.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/domain/suggestion_engine.dart';
import 'package:autiplan/features/caregiver/account_screen.dart';
import 'package:autiplan/features/caregiver/home_screen.dart';
import 'package:autiplan/features/caregiver/schedule_screen.dart';
import 'package:autiplan/features/child/child_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fixture_state.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });
  group('Clock bisa di-override', () {
    test('Clock(() => t).now == t', () {
      final t = DateTime(2026, 5, 1, 16, 0);
      final clock = Clock(() => t);
      expect(clock.now, t);
    });
  });

  group('initialsOf', () {
    test('Bu Sari → BS', () {
      expect(initialsOf('Bu Sari'), 'BS');
    });

    test('Rafi → R', () {
      expect(initialsOf('Rafi'), 'R');
    });

    test('kosong → ?', () {
      expect(initialsOf(''), '?');
    });
  });

  group('Settings tanpa demoClockEnabled', () {
    test('fromJson tidak melempar', () {
      expect(
        () => Settings.fromJson({'demoClockEnabled': true}),
        returnsNormally,
      );
    });

    test('toJson tidak memuat demoClockEnabled', () {
      const settings = Settings();
      expect(settings.toJson().containsKey('demoClockEnabled'), isFalse);
    });
  });

  group('generateSuggestions dengan state kosong', () {
    test('mengembalikan []', () {
      final suggestions = generateSuggestions(
        AppState.empty(),
        DateTime(2026, 5, 1, 16, 0),
        'child-x',
      );
      expect(suggestions, isEmpty);
    });
  });

  group('Widget dengan AppState.empty', () {
    Widget wrap(Widget child) => ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(InMemoryRepository(), AppState.empty()),
        ),
      ],
      child: MaterialApp(home: child),
    );

    testWidgets('CaregiverHomeScreen tidak exception', (tester) async {
      await tester.pumpWidget(wrap(const CaregiverHomeScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CaregiverScheduleScreen tidak exception', (tester) async {
      await tester.pumpWidget(wrap(const CaregiverScheduleScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CaregiverAccountScreen tidak exception', (tester) async {
      await tester.pumpWidget(wrap(const CaregiverAccountScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ChildHomeScreen tidak exception', (tester) async {
      await tester.pumpWidget(wrap(const ChildHomeScreen()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Widget bergantung jam', () {
    testWidgets('kartu status berpindah saat jam berubah', (tester) async {
      final state = buildFixtureState();

      Future<void> pumpAt(DateTime now) async {
        final container = ProviderContainer(
          overrides: [
            appStateProvider.overrideWith(
              (ref) => AppStateNotifier(InMemoryRepository(), state),
            ),
            clockProvider.overrideWithValue(Clock(() => now)),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: CaregiverHomeScreen()),
          ),
        );
        await tester.pump();
      }

      // 15.59: Sepeda Santai (16.00) belum mulai, jadi masih "BERIKUTNYA".
      await pumpAt(DateTime(2026, 5, 1, 15, 59));
      expect(find.textContaining('BERIKUTNYA'), findsWidgets);
      expect(find.textContaining('SEKARANG'), findsNothing);

      // 16.00: Sepeda Santai menjadi "SEKARANG".
      await pumpAt(DateTime(2026, 5, 1, 16, 0));
      expect(find.textContaining('SEKARANG'), findsWidgets);
    });
  });
}
