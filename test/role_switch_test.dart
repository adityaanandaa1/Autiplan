import 'package:autiplan/app.dart';
import 'package:autiplan/data/local_repository.dart';
import 'package:autiplan/data/providers.dart';
import 'support/fixture_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appStateProvider.overrideWith(
          (ref) =>
              AppStateNotifier(LocalRepository(prefs), buildFixtureState()),
        ),
      ],
      child: const AutiPlanApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const switchLabel = 'Ganti peran';
  const pickerText = 'Pilih peran untuk demo';

  testWidgets(
    'Beranda orang tua punya tombol Ganti peran yang kembali ke Pilih peran',
    (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Orang tua · Bu Sari'));
      await tester.pumpAndSettle();

      // Tombol di akhir ListView: gulir dulu supaya ter-build.
      await tester.scrollUntilVisible(
        find.text(switchLabel),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text(switchLabel), findsOneWidget);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();

      expect(find.text(pickerText), findsOneWidget);
    },
  );

  testWidgets('Tombol Ganti peran hanya di Beranda, bukan di tab Jadwal', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Orang tua · Bu Sari'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwal'));
    await tester.pumpAndSettle();

    expect(find.text(switchLabel), findsNothing);
  });

  testWidgets(
    'Jadwal anak punya tombol Ganti peran yang kembali ke Pilih peran',
    (tester) async {
      await _pumpApp(tester);
      await tester.tap(find.text('Anak · Rafi'));
      await tester.pumpAndSettle();

      expect(find.text(switchLabel), findsOneWidget);

      await tester.tap(find.text(switchLabel));
      await tester.pumpAndSettle();

      expect(find.text(pickerText), findsOneWidget);
    },
  );
}
