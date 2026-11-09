// Pembantu bersama tes widget Tahap 5 (bukan tes; main kosong supaya
// `flutter test test/tahap5_*` tidak gagal).
import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'support/in_memory_repository.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'support/fixture_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {}

class SheetHost {
  SheetHost(this.container);
  final ProviderContainer container;
  AppState get state => container.read(appStateProvider);
  void setState(AppState s) =>
      container.read(appStateProvider.notifier).updateState(s);
}

Child rafiOf(AppState s) => s.children.firstWhere((c) => c.name == 'Rafi');

Activity activityTitled(AppState s, String title) =>
    s.activities.firstWhere((a) => a.title == title);

/// Memasang aplikasi mini berisi tombol "buka-sheet" yang membuka sheet lewat
/// `showModalBottomSheet` (sama seperti kode produksi), lalu membukanya.
Future<SheetHost> pumpSheet(
  WidgetTester tester,
  Widget Function(BuildContext context, AppState state) sheetBuilder, {
  AppState? initial,
  Size size = const Size(430, 1600),
}) => pumpOpener(
  tester,
  (ctx, state) => showModalBottomSheet<void>(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: AppColors.transparan,
    builder: (sheetCtx) => sheetBuilder(sheetCtx, state),
  ),
  initial: initial,
  size: size,
);

/// Seperti [pumpSheet], tetapi tombol "buka-sheet" menjalankan [opener]
/// (mis. membuka detail saran).
Future<SheetHost> pumpOpener(
  WidgetTester tester,
  void Function(BuildContext context, AppState state) opener, {
  AppState? initial,
  Size size = const Size(430, 1600),
}) async {
  await initializeDateFormatting('id_ID');
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(Clock(() => fixtureNow)),
      appStateProvider.overrideWith(
        (ref) => AppStateNotifier(
          InMemoryRepository(),
          initial ?? buildFixtureState(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildParentTheme(childPalette: ChildPalette.lautTenang),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () => opener(ctx, container.read(appStateProvider)),
                child: const Text('buka-sheet'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('buka-sheet'));
  await tester.pumpAndSettle();
  return SheetHost(container);
}

/// Mengisi kolom teks ke-[index] (urutan kemunculan di layar).
Future<void> enterTextAt(WidgetTester tester, int index, String text) async {
  final field = find.byType(TextField).at(index);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// TextField dengan teks bantu [hint] (mis. 'Langkah 1').
Finder fieldWithHint(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);
