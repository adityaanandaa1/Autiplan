import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/widgets/live_tutor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

void main() {
  testWidgets('Live Tutor dialog dapat dibuka dan dinavigasikan langkah 1 s.d. 5', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWithValue(testCaregiverSession),
          sharedPreferencesProvider.overrideWithValue(prefs),
          appStateProvider.overrideWith(
            (ref) => AppStateNotifier(InMemoryRepository(), buildFixtureState()),
          ),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            return MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => showCaregiverLiveTutor(ctx, ref),
                    child: const Text('Buka Live Tutor'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Buka Live Tutor
    await tester.tap(find.text('Buka Live Tutor'));
    await tester.pumpAndSettle();

    // Langkah 1
    expect(find.text('Pemilihan & Filter Anak'), findsOneWidget);
    expect(find.text('1 dari 5 · Pengalihan Anak'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);

    // Klik Lanjut -> Langkah 2
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Kalender & Navigasi Mingguan'), findsOneWidget);
    expect(find.text('Sebelumnya'), findsOneWidget);

    // Klik Lanjut -> Langkah 3
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Jadwal & Template Rutinitas'), findsOneWidget);

    // Klik Lanjut -> Langkah 4
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Jeda Transisi & Waktu Tenang'), findsOneWidget);

    // Klik Lanjut -> Langkah 5
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Sisi Anak & Tombol Darurat'), findsOneWidget);
    expect(find.text('Selesai & Mulai'), findsOneWidget);

    // Klik Selesai & Mulai
    await tester.tap(find.text('Selesai & Mulai'));
    await tester.pumpAndSettle();

    // Dialog tertutup
    expect(find.text('Sisi Anak & Tombol Darurat'), findsNothing);

    // Preference tersimpan
    expect(prefs.getBool('has_seen_caregiver_live_tutor'), isTrue);
  });
}
