import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/domain/routine_templates.dart';
import 'package:autiplan/features/caregiver/widgets/routine_template_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'support/test_session.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  Future<(ProviderContainer, AppStateNotifier)> pumpTemplateSheet(
    WidgetTester tester, {
    AppState? initialState,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final s = initialState ?? buildFixtureState();
    final repo = InMemoryRepository();
    final notifier = AppStateNotifier(repo, s);
    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWithValue(testCaregiverSession),
          sharedPreferencesProvider.overrideWithValue(prefs),
          appStateProvider.overrideWith((ref) => notifier),
        ],
        child: Consumer(
          builder: (context, ref, child) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () {
                      final child = ref.read(currentChildProvider)!;
                      showRoutineTemplateSheet(
                        ctx,
                        ref,
                        child: child,
                        date: DateTime(2026, 5, 1),
                      );
                    },
                    child: const Text('Buka Template'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    // Buka sheet
    await tester.tap(find.text('Buka Template'));
    await tester.pumpAndSettle();

    return (container, notifier);
  }

  testWidgets('menampilkan header dan paket rutinitas', (tester) async {
    await pumpTemplateSheet(tester);

    expect(find.text('Template Rutinitas'), findsOneWidget);
    expect(find.text('Paket Lengkap (${routinePacks.length})'), findsOneWidget);
    expect(find.text('Pilihan Kegiatan (${allRoutineTemplates.length})'), findsOneWidget);

    // Paket malam spiritual tampil
    expect(find.text('Paket Malam Spiritual & Tidur Tenang'), findsOneWidget);
  });

  testWidgets('berpindah ke tab pilihan kegiatan 23 opsi', (tester) async {
    await pumpTemplateSheet(tester);

    // Ketuk tab pilihan kegiatan
    await tester.tap(find.text('Pilihan Kegiatan (${allRoutineTemplates.length})'));
    await tester.pumpAndSettle();

    // Chip filter tampil
    expect(find.text('Semua (${allRoutineTemplates.length})'), findsOneWidget);
    expect(find.textContaining('Malam & Spiritual'), findsOneWidget);

    // Salah satu kegiatan tampil
    expect(find.text('Bangun & Rapikan Tempat Tidur'), findsOneWidget);
  });

  testWidgets('menerapkan paket menambahkan seluruh kegiatan paket ke state', (tester) async {
    final (_, notifier) = await pumpTemplateSheet(tester);
    final initialCount = notifier.state.activities.length;

    // Ketuk tombol Terapkan Paket pertama
    final applyButton = find.textContaining('Terapkan Paket').first;
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    // Kegiatan bertambah
    expect(notifier.state.activities.length, greaterThan(initialCount));
    // Sheet tertutup
    expect(find.text('Template Rutinitas'), findsNothing);
  });
}
