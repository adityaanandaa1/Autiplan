import 'package:autiplan/app.dart';
import 'package:autiplan/core/clock.dart';
import 'support/in_memory_repository.dart';
import 'package:autiplan/data/providers.dart';
import 'support/fixture_state.dart';
import 'package:autiplan/features/caregiver/caregiver_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = InMemoryRepository();
  final seedState = buildFixtureState();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(Clock(() => fixtureNow)),
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(repo, seedState),
        ),
      ],
      child: const AutiPlanApp(),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets('Aplikasi terbuka di layar Pilih Peran (10.2)', (tester) async {
    await _pumpApp(tester);

    expect(find.text('AutiPlan'), findsOneWidget);
    expect(find.text('Pilih peran untuk demo'), findsOneWidget);
    expect(find.text('Orang tua · Bu Sari'), findsOneWidget);
    expect(find.text('Anak · Rafi'), findsOneWidget);
  });

  testWidgets(
    'Ketuk Orang tua masuk ke CaregiverShell dan keluar dari picker',
    (tester) async {
      await _pumpApp(tester);

      await tester.tap(find.text('Orang tua · Bu Sari'));
      await tester.pumpAndSettle();

      expect(find.byType(CaregiverShell), findsOneWidget);
      expect(find.text('Pilih peran untuk demo'), findsNothing);
    },
  );

  testWidgets('Ketuk Anak masuk ke jadwal anak dan menyimpan peran', (
    tester,
  ) async {
    final prefs = await _pumpApp(tester);

    await tester.tap(find.text('Anak · Rafi'));
    await tester.pumpAndSettle();

    // Layar anak punya sapaan (Selamat pagi/siang/sore/malam) dan nama Halo, Rafi!
    expect(find.textContaining('Halo, Rafi!'), findsOneWidget);
    expect(find.byType(CaregiverShell), findsNothing);
    expect(find.text('Pilih peran untuk demo'), findsNothing);
    expect(prefs.getString('last_selected_role'), 'child');
  });
}
