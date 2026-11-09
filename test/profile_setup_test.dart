import 'package:autiplan/app.dart';
import 'support/in_memory_repository.dart';
import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/core/widgets/initials.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/domain/phone_number.dart';
import 'package:autiplan/features/child/child_calling_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';

Future<ProviderContainer> _pumpEmptyApp(WidgetTester tester) async {
  await initializeDateFormatting('id_ID');
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      clockProvider.overrideWithValue(Clock(() => fixtureNow)),
      appStateProvider.overrideWith(
        (ref) => AppStateNotifier(InMemoryRepository(), AppState.empty()),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const AutiPlanApp()),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _fill(
  WidgetTester tester, {
  String age = '12',
  String emergency = '081234567890',
  String backup = '',
}) async {
  final values = ['Ibu', 'Nama Lengkap', 'Nama', age, emergency, backup];
  for (var i = 0; i < values.length; i++) {
    await tester.enterText(find.byType(TextField).at(i), values[i]);
  }
  await tester.pump();
  await tester.tap(find.text('Mulai pakai AutiPlan'));
  await tester.pumpAndSettle();
}

void main() {
  group('nomor telepon', () {
    test('spasi dan tanda hubung dibuang', () {
      expect(normalizePhoneNumber('0812-3456 7890'), '081234567890');
    });

    test('hanya nomor seluler 08 yang sah', () {
      expect(isValidPhoneNumber('081234567890'), isTrue);
      expect(isValidPhoneNumber('abc'), isFalse);
      expect(isValidPhoneNumber('0812'), isFalse);
    });
  });

  group('initialsOf karakter khusus', () {
    test('emoji tidak terpotong', () {
      expect(initialsOf('😀 Sari'), '😀S');
    });
  });

  group('alur akun baru', () {
    testWidgets('tanpa anak langsung ke profil awal', (tester) async {
      await _pumpEmptyApp(tester);
      expect(find.text('Kenalan dulu'), findsOneWidget);
    });

    testWidgets('nomor berformat 0812-3456-7890 diterima dan dinormalkan', (
      tester,
    ) async {
      final container = await _pumpEmptyApp(tester);
      await _fill(tester, emergency: '0812-3456-7890');

      final state = container.read(appStateProvider);
      expect(state.children, hasLength(1));
      expect(state.settings.emergencyNumber, '081234567890');
      expect(find.text('Kenalan dulu'), findsNothing);
    });

    for (final age in ['0', '-5', '0x10', '999']) {
      testWidgets('umur "$age" ditolak', (tester) async {
        final container = await _pumpEmptyApp(tester);
        await _fill(tester, age: age);
        expect(container.read(appStateProvider).children, isEmpty);
      });
    }

    testWidgets('galat cadangan muncul hanya sekali, di kolom cadangan', (
      tester,
    ) async {
      final container = await _pumpEmptyApp(tester);
      await _fill(tester, backup: '123');

      expect(container.read(appStateProvider).children, isEmpty);
      final error = find.text('Nomor belum sesuai. Contoh: 081234567890.');
      expect(error, findsOneWidget);
      expect(
        tester.getTopLeft(error).dy,
        greaterThan(tester.getTopLeft(find.byType(TextField).at(5)).dy),
      );
    });
  });

  group('kontak cadangan kosong di A-08', () {
    Widget app(String backup) => ProviderScope(
      overrides: [
        appStateProvider.overrideWith(
          (ref) => AppStateNotifier(
            InMemoryRepository(),
            AppState.empty().copyWith(
              settings: Settings(
                caregiverName: 'Ibu',
                emergencyNumber: '081234567890',
                backupNumber: backup,
              ),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: buildParentTheme(childPalette: ChildPalette.lautTenang),
        home: const ChildCallingScreen(),
      ),
    );

    testWidgets('tidak menawarkan tombol maupun janji cadangan', (
      tester,
    ) async {
      await tester.pumpWidget(app(''));
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Telepon kontak cadangan'), findsNothing);
      expect(find.textContaining('kontak cadangan'), findsNothing);
    });

    testWidgets('tombol muncul setelah 30 detik bila ada nomor', (
      tester,
    ) async {
      await tester.pumpWidget(app('081298765432'));
      expect(find.text('Telepon kontak cadangan'), findsNothing);
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Telepon kontak cadangan'), findsOneWidget);
    });
  });
}
