import 'package:autiplan/core/widgets/buttons.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/features/caregiver/forms/form_field.dart';
import 'package:autiplan/features/caregiver/forms/sheet_scaffold.dart';
import 'package:autiplan/features/caregiver/forms/time_feedback.dart';
import 'package:autiplan/features/caregiver/forms/time_picker_sheet.dart';
import 'package:autiplan/features/caregiver/widgets/add_activity_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tahap5_helpers.dart';

final _friday = DateTime(2026, 5, 1);

PrimaryButton _save(WidgetTester tester) => tester.widget<PrimaryButton>(
  find.widgetWithText(PrimaryButton, 'Simpan jadwal'),
);

Widget _add(
  BuildContext ctx,
  AppState s, {
  String? title,
  ActivityIcon? icon,
  TimeOfDayLite? start,
  TimeOfDayLite? end,
  String? suggestionId,
}) => AddActivitySheet(
  childId: rafiOf(s).id,
  initialDate: _friday,
  initialTitle: title,
  initialIcon: icon,
  initialStart: start,
  initialEnd: end,
  suggestionId: suggestionId,
);

Future<void> _tapSave(WidgetTester tester) async {
  final f = find.widgetWithText(PrimaryButton, 'Simpan jadwal');
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('Alur 13.2: tambah jadwal dengan pemeriksaan bentrok', () {
    testWidgets('bentrok -> tautan slot -> simpan; tanpa ChangeNotice', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (c, s) => _add(
          c,
          s,
          start: const TimeOfDayLite(16, 30),
          end: const TimeOfDayLite(17, 15),
        ),
      );
      expect(find.text('Tambah jadwal'), findsOneWidget);
      expect(find.text('Opsi lanjutan'), findsOneWidget);
      expect(_save(tester).enabled, isFalse);

      await enterTextAt(tester, 0, 'Mandi Sore');
      await tapText(tester, 'Pilih ikon');
      await tapText(tester, 'Mandi');

      expect(
        find.text(
          'Waktu ini bentrok dengan Sepeda Santai (16.00–17.00). '
          'Pilih waktu lain supaya Rafi tidak bingung.',
        ),
        findsOneWidget,
      );
      expect(_save(tester).enabled, isFalse);

      await tapText(tester, 'Pakai 17.10 – 17.55');
      expect(find.textContaining('bentrok'), findsNothing);
      expect(find.textContaining('17.10 – 17.55'), findsOneWidget);
      expect(_save(tester).enabled, isTrue);

      await _tapSave(tester);

      final saved = activityTitled(host.state, 'Mandi Sore');
      expect(saved.start, const TimeOfDayLite(17, 10));
      expect(saved.end, const TimeOfDayLite(17, 55));
      expect(saved.icon, ActivityIcon.mandi);
      expect(saved.shortTitle, 'Mandi Sore');
      expect(host.state.notices, isEmpty);
      expect(
        find.text('Jadwal tersimpan dan dikirim ke HP Rafi'),
        findsOneWidget,
      );
    });

    testWidgets('B1: teks bantu jeda < 10 menit', (tester) async {
      await pumpSheet(
        tester,
        (c, s) => _add(
          c,
          s,
          title: 'Mandi',
          icon: ActivityIcon.mandi,
          start: const TimeOfDayLite(17, 5),
          end: const TimeOfDayLite(17, 35),
        ),
      );
      expect(find.text('Jeda dengan Sepeda Santai hanya 5 menit.'), findsOne);
      expect(_save(tester).enabled, isTrue);
    });

    testWidgets('B1: jeda 15 menit tidak menampilkan teks bantu', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        (c, s) => _add(
          c,
          s,
          title: 'Mandi',
          icon: ActivityIcon.mandi,
          start: const TimeOfDayLite(17, 15),
          end: const TimeOfDayLite(17, 45),
        ),
      );
      expect(find.textContaining('Jeda dengan'), findsNothing);
    });
  });

  group('Bug 4 dan 5: Selesai harus setelah Mulai', () {
    testWidgets('Selesai < Mulai: pesan tenang dan simpan nonaktif', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        (c, s) => _add(
          c,
          s,
          title: 'Mandi',
          icon: ActivityIcon.mandi,
          start: const TimeOfDayLite(17, 0),
          end: const TimeOfDayLite(16, 0),
        ),
      );
      expect(find.text('Jam selesai harus setelah jam mulai.'), findsOneWidget);
      expect(_save(tester).enabled, isFalse);
    });

    testWidgets('ganti ikon Tidur ke ikon lain mengembalikan jam selesai', (
      tester,
    ) async {
      await pumpSheet(tester, (c, s) => _add(c, s, title: 'Tes'));
      await tapText(tester, 'Pilih ikon');
      await tapText(tester, 'Tidur');
      expect(find.textContaining('17.15 – Pagi'), findsOneWidget);

      await tapText(tester, 'Ganti');
      await tapText(tester, 'Main');
      expect(find.textContaining('17.15 – 17.45'), findsOneWidget);
      expect(find.textContaining('Pagi'), findsNothing);
      expect(_save(tester).enabled, isTrue);
    });

    test('end null untuk ikon selain Tidur menghalangi simpan', () {
      final a = Activity(
        id: 'a',
        childId: 'child-rafi',
        title: 'Main',
        shortTitle: 'Main',
        icon: ActivityIcon.main,
        date: _friday,
        start: const TimeOfDayLite(10, 0),
      );
      expect(TimeFeedback.blocksSave(a, const []), isTrue);
      expect(
        TimeFeedback.blocksSave(a.copyWith(icon: ActivityIcon.tidur), const []),
        isFalse,
      );
    });

    testWidgets('pemilih waktu: Simpan waktu nonaktif bila Selesai <= Mulai', (
      tester,
    ) async {
      await pumpOpener(
        tester,
        (ctx, s) => showDateTimePickerSheet(
          ctx,
          initialDate: _friday,
          initialStart: const TimeOfDayLite(17, 0),
          initialEnd: const TimeOfDayLite(16, 0),
          allowClearEnd: false,
        ),
      );
      expect(find.text('Jam selesai harus setelah jam mulai.'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.widgetWithText(PrimaryButton, 'Simpan waktu'),
            )
            .enabled,
        isFalse,
      );
    });

    testWidgets('pemilih waktu: kosong boleh hanya bila allowClearEnd', (
      tester,
    ) async {
      await pumpOpener(
        tester,
        (ctx, s) => showDateTimePickerSheet(
          ctx,
          initialDate: _friday,
          initialStart: const TimeOfDayLite(21, 0),
          allowClearEnd: false,
        ),
      );
      expect(find.textContaining('Hanya kegiatan Tidur'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.widgetWithText(PrimaryButton, 'Simpan waktu'),
            )
            .enabled,
        isFalse,
      );
    });

    testWidgets('pemilih waktu: Tidur boleh tanpa Selesai', (tester) async {
      await pumpOpener(
        tester,
        (ctx, s) => showDateTimePickerSheet(
          ctx,
          initialDate: _friday,
          initialStart: const TimeOfDayLite(21, 0),
          allowClearEnd: true,
        ),
      );
      expect(
        tester
            .widget<PrimaryButton>(
              find.widgetWithText(PrimaryButton, 'Simpan waktu'),
            )
            .enabled,
        isTrue,
      );
    });
  });

  group('Nama singkat (§8.6, bug 10)', () {
    testWidgets('otomatis dua kata pertama Nama; manual maks 2 kata', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (c, s) => _add(c, s, icon: ActivityIcon.main),
      );
      await enterTextAt(tester, 0, 'Bermain bola sore');
      await tapText(tester, 'Langkah & pengulangan');

      final shortField = fieldWithHint('Bawaan: 2 kata pertama');
      expect(
        tester.widget<TextField>(shortField).controller!.text,
        'Bermain bola',
      );

      await tester.enterText(shortField, 'Satu dua tiga');
      await tester.pump();
      expect(find.text('Nama singkat maksimal 2 kata.'), findsOneWidget);
      expect(_save(tester).enabled, isFalse);

      await tester.enterText(shortField, 'Bola');
      await tester.pump();
      expect(find.text('Nama singkat maksimal 2 kata.'), findsNothing);
      expect(_save(tester).enabled, isTrue);

      // Nama diubah setelah nama singkat diisi manual: nama singkat tetap.
      await enterTextAt(tester, 0, 'Bermain bola malam');
      expect(tester.widget<TextField>(shortField).controller!.text, 'Bola');

      await _tapSave(tester);
      expect(
        activityTitled(host.state, 'Bermain bola malam').shortTitle,
        'Bola',
      );
    });
  });

  group('B6: langkah bisa ditambah, dihapus, dan diurutkan', () {
    testWidgets('urutan langkah tersimpan sesuai urutan baru', (tester) async {
      final host = await pumpSheet(
        tester,
        (c, s) => _add(c, s, title: 'Tes langkah', icon: ActivityIcon.main),
      );
      await tapText(tester, 'Langkah & pengulangan');
      await tapText(tester, '+ Tambah langkah');
      await tapText(tester, '+ Tambah langkah');
      await tapText(tester, '+ Tambah langkah');
      await tester.enterText(fieldWithHint('Langkah 1'), 'A');
      await tester.enterText(fieldWithHint('Langkah 2'), 'B');
      await tester.enterText(fieldWithHint('Langkah 3'), 'C');
      await tester.pump();

      // Hapus langkah 3 (C), lalu seret langkah 1 (A) ke bawah langkah 2.
      await tester.ensureVisible(find.byTooltip('Hapus langkah 3'));
      await tester.tap(find.byTooltip('Hapus langkah 3'));
      await tester.pumpAndSettle();
      expect(fieldWithHint('Langkah 3'), findsNothing);

      final handle = find.byIcon(LucideIcons.gripVertical).first;
      await tester.ensureVisible(handle);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      await _tapSave(tester);
      expect(activityTitled(host.state, 'Tes langkah').steps, ['B', 'A']);
    });
  });

  group('Bug 8: status saran applied setelah jadwal tersimpan (§9.1)', () {
    testWidgets(
      'sheet Tambah dari saran menandai applied hanya setelah simpan',
      (tester) async {
        final host = await pumpSheet(
          tester,
          (c, s) => _add(
            c,
            s,
            title: 'Waktu tenang',
            icon: ActivityIcon.tidur,
            start: const TimeOfDayLite(19, 15),
            end: const TimeOfDayLite(19, 45),
            suggestionId: 'quietTime:x',
          ),
        );
        expect(host.state.suggestionStatus['quietTime:x'], isNull);
        await _tapSave(tester);
        expect(
          host.state.suggestionStatus['quietTime:x'],
          SuggestionStatus.applied,
        );
      },
    );
  });

  group('Bug 7: keyboard tidak menutupi isian', () {
    testWidgets('SheetScaffold naik setinggi viewInsets.bottom', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SheetScaffold(
                title: 'Uji',
                child: FormBox(child: TextField()),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomLeft(
              find
                  .descendant(
                    of: find.byType(SheetScaffold),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .dy,
        lessThanOrEqualTo(800 - 300),
      );
      expect(
        tester.getBottomLeft(find.byType(TextField)).dy,
        lessThanOrEqualTo(800 - 300),
      );
    });

    testWidgets('sheet Tambah sungguhan: dasar sheet di atas keyboard', (
      tester,
    ) async {
      await pumpSheet(tester, (c, s) => _add(c, s), size: const Size(430, 900));
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(
        tester
            .getBottomLeft(
              find
                  .descendant(
                    of: find.byType(SheetScaffold),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .dy,
        lessThanOrEqualTo(900 - 400),
      );
    });
  });
}
