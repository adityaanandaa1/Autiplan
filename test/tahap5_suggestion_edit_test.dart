import 'package:autiplan/core/widgets/buttons.dart';
import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:autiplan/domain/suggestion_engine.dart';
import 'package:autiplan/features/caregiver/widgets/edit_activity_sheet.dart';
import 'package:autiplan/features/caregiver/widgets/suggestion_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'tahap5_helpers.dart';

PrimaryButton _button(WidgetTester tester, String label) =>
    tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, label));

Future<void> _tapButton(WidgetTester tester, String label) async {
  final f = find.widgetWithText(PrimaryButton, label);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Widget _edit(
  AppState s,
  String title, {
  TimeOfDayLite? prefillStart,
  TimeOfDayLite? prefillEnd,
}) => EditActivitySheet(
  activity: activityTitled(s, title),
  child: rafiOf(s),
  prefillStart: prefillStart,
  prefillEnd: prefillEnd,
);

/// Seed + "Mandi Sore" 17.05-17.35 (jeda 5 menit setelah Sepeda Santai).
AppState _withShortGap() {
  final s = buildFixtureState();
  final rafi = rafiOf(s);
  return s.copyWith(
    activities: [
      ...s.activities,
      Activity(
        id: 'mandi-sore',
        childId: rafi.id,
        title: 'Mandi Sore',
        shortTitle: 'Mandi',
        icon: ActivityIcon.mandi,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(17, 5),
        end: const TimeOfDayLite(17, 35),
      ),
    ],
  );
}

void main() {
  group('Bug 3: saran transitionGap "Geser" bisa diterapkan (alur §9.2)', () {
    testWidgets(
      'baseline = kegiatan asli; pesan wajib; applied; saran hilang',
      (tester) async {
        final initial = _withShortGap();
        final suggestion = generateSuggestions(
          initial,
          fixtureNow,
          rafiOf(initial).id,
        ).firstWhere((s) => s.type == SuggestionType.transitionGap);
        expect(suggestion.actionLabel, 'Geser Mandi Sore');

        final host = await pumpOpener(
          tester,
          (ctx, s) => showSuggestionDetailSheet(ctx, suggestion: suggestion),
          initial: initial,
        );
        await tapText(tester, 'Geser Mandi Sore');

        // Sheet Ubah terbuka dengan jam sudah digeser 5 menit.
        expect(find.text('Ubah jadwal'), findsOneWidget);
        expect(find.textContaining('17.10 – 17.40'), findsOneWidget);
        // Dasar "sebelum" = kegiatan asli, jadi ini perubahan inti.
        expect(find.text('Pesan untuk Rafi'), findsOneWidget);
        expect(_button(tester, 'Kirim perubahan').enabled, isFalse);

        await enterTextAt(
          tester,
          1,
          'Ada jeda sepuluh menit setelah bersepeda.',
        );
        expect(_button(tester, 'Kirim perubahan').enabled, isTrue);
        await _tapButton(tester, 'Kirim perubahan');
        expect(tester.takeException(), isNull);

        final moved = activityTitled(host.state, 'Mandi Sore');
        expect(moved.start, const TimeOfDayLite(17, 10));
        expect(moved.end, const TimeOfDayLite(17, 40));
        expect(host.state.notices, hasLength(1));
        expect(
          host.state.notices.single.before.start,
          const TimeOfDayLite(17, 5),
        );
        expect(
          host.state.notices.single.after!.start,
          const TimeOfDayLite(17, 10),
        );
        expect(find.text('Perubahan terkirim ke Rafi'), findsOneWidget);

        // Bug 8: applied dan hilang dari daftar saran.
        expect(
          host.state.suggestionStatus[suggestion.id],
          SuggestionStatus.applied,
        );
        expect(
          generateSuggestions(
            host.state,
            fixtureNow,
            rafiOf(host.state).id,
          ).where((s) => s.type == SuggestionType.transitionGap),
          isEmpty,
        );
      },
    );
  });

  group('Alur 13.5: saran Latihan mandiri', () {
    testWidgets('Kurangi langkah -> mode mandiri, applied, snackbar', (
      tester,
    ) async {
      final seed = buildFixtureState();
      final suggestion = generateSuggestions(
        seed,
        fixtureNow,
        rafiOf(seed).id,
      ).firstWhere((s) => s.type == SuggestionType.independence);

      final host = await pumpOpener(
        tester,
        (ctx, s) => showSuggestionDetailSheet(ctx, suggestion: suggestion),
      );
      await tapText(tester, 'Kurangi langkah');

      expect(
        activityTitled(host.state, 'Sepeda Santai').independentMode,
        isTrue,
      );
      expect(
        host.state.suggestionStatus[suggestion.id],
        SuggestionStatus.applied,
      );
      expect(
        find.text('Mode mandiri aktif untuk Sepeda Santai'),
        findsOneWidget,
      );
      expect(
        generateSuggestions(
          host.state,
          fixtureNow,
          rafiOf(host.state).id,
        ).where((s) => s.type == SuggestionType.independence),
        isEmpty,
      );
    });
  });

  group('Bug 4: validasi waktu di form Ubah', () {
    testWidgets('Selesai <= Mulai: pesan dan tombol tetap nonaktif', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        (c, s) => _edit(
          s,
          'Les dengan Pak Lana',
          prefillStart: const TimeOfDayLite(20, 30),
          prefillEnd: const TimeOfDayLite(20, 10),
        ),
      );
      expect(find.text('Jam selesai harus setelah jam mulai.'), findsOneWidget);
      await enterTextAt(tester, 1, 'Mengubah jam.');
      expect(_button(tester, 'Kirim perubahan').enabled, isFalse);
    });
  });

  group('Bug 5: Selesai kosong hanya untuk ikon Tidur', () {
    testWidgets(
      'Tidur -> ikon lain mengembalikan Selesai; kembali ke Tidur = Pagi',
      (tester) async {
        await pumpSheet(tester, (c, s) => _edit(s, 'Istirahat & Tidur Malam'));
        expect(find.textContaining('21.00 – Pagi'), findsOneWidget);

        await tapText(tester, 'Ganti');
        await tapText(tester, 'Nonton');
        expect(find.textContaining('21.00 – 21.30'), findsOneWidget);
        expect(find.textContaining('Pagi'), findsNothing);

        await tapText(tester, 'Ganti');
        await tapText(tester, 'Tidur');
        expect(find.textContaining('21.00 – Pagi'), findsOneWidget);
      },
    );
  });

  group('Bug 6: ubah tanggal saja bisa disimpan', () {
    testWidgets('tanggal berpindah, tombol "Simpan", tanpa ChangeNotice', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (c, s) => _edit(s, 'Les dengan Pak Lana'),
      );
      expect(_button(tester, 'Kirim perubahan').enabled, isFalse);

      await tapText(tester, 'Jumat, 1 Mei · 20.00 – 20.45');
      await tapText(tester, 'Sabtu, 2 Mei');
      await tapText(tester, 'Simpan waktu');

      expect(_button(tester, 'Simpan').enabled, isTrue);
      expect(find.text('Pesan untuk Rafi'), findsNothing);
      await _tapButton(tester, 'Simpan');

      final moved = activityTitled(host.state, 'Les dengan Pak Lana');
      expect(moved.date, DateTime(2026, 5, 2));
      expect(host.state.notices, isEmpty);
    });
  });

  group('Bug 9: nama kosong di form Ubah', () {
    testWidgets('kosong atau spasi: validasi tampil, tidak pakai nama lama', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (c, s) => _edit(s, 'Les dengan Pak Lana'),
      );
      await enterTextAt(tester, 0, '   ');
      expect(find.text('Nama kegiatan wajib diisi.'), findsOneWidget);
      await enterTextAt(tester, 1, 'Pesan apa saja.');
      expect(_button(tester, 'Kirim perubahan').enabled, isFalse);
      expect(
        host.state.activities.where((a) => a.title == 'Les dengan Pak Lana'),
        hasLength(1),
      );

      await enterTextAt(tester, 0, 'Les');
      expect(find.text('Nama kegiatan wajib diisi.'), findsNothing);
      expect(_button(tester, 'Kirim perubahan').enabled, isTrue);
    });
  });

  group('Nama singkat di form Ubah', () {
    testWidgets('isian manual tidak ditimpa saat Nama berubah', (tester) async {
      final host = await pumpSheet(
        tester,
        (c, s) => _edit(s, 'Les dengan Pak Lana'),
      );
      await tapText(tester, 'Langkah & pengulangan');
      await tester.enterText(fieldWithHint('Bawaan: 2 kata pertama'), 'Film');
      await tester.pump();
      await enterTextAt(tester, 0, 'Nonton film bersama');
      await enterTextAt(tester, 1, 'Pak Lana sakit.');
      await _tapButton(tester, 'Kirim perubahan');
      expect(
        activityTitled(host.state, 'Nonton film bersama').shortTitle,
        'Film',
      );
    });
  });

  group('B2: kartu saran kontekstual', () {
    testWidgets('"Lihat alasannya" membuka detail saran quietTime', (
      tester,
    ) async {
      await pumpSheet(tester, (c, s) => _edit(s, 'Les dengan Pak Lana'));
      // Les bukan kegiatan layar: belum ada kartu.
      expect(find.text('Lihat alasannya'), findsNothing);

      await enterTextAt(tester, 0, 'Nonton film bersama');
      await tapText(tester, 'Ganti');
      await tapText(tester, 'Nonton');
      expect(
        find.text(
          'Nonton film bersama selesai 15 menit sebelum tidur. '
          'Layar menjelang tidur bisa membuat Rafi lebih lama tertidur. '
          'Tambahkan waktu tenang tanpa layar?',
        ),
        findsOneWidget,
      );

      await tapText(tester, 'Lihat alasannya');
      expect(find.text('Waktu tenang sebelum tidur'), findsOneWidget);
      expect(find.text('Kenapa saran ini?'), findsOneWidget);
      expect(
        find.textContaining(
          'Nonton film bersama selesai pukul 20.45, tidur pukul 21.00.',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'aksi detail memakai jam selesai hasil ubahan, bukan data lama',
      (tester) async {
        final host = await pumpSheet(
          tester,
          (c, s) => _edit(
            s,
            'Les dengan Pak Lana',
            prefillStart: const TimeOfDayLite(20, 0),
            prefillEnd: const TimeOfDayLite(20, 50),
          ),
        );
        await tapText(tester, 'Ganti');
        await tapText(tester, 'Nonton');
        await tapText(tester, 'Lihat alasannya');
        await tapText(tester, 'Tambahkan waktu tenang');

        expect(find.text('Tambah jadwal'), findsOneWidget);
        expect(find.textContaining('20.50 – 21.20'), findsOneWidget);
        expect(host.state.suggestionStatus, isEmpty);
      },
    );
  });

  group('B8: pratinjau Dulu -> Sekarang bergaya A-02', () {
    testWidgets('ubin, panah, kotak alasan; tanpa teks karangan', (
      tester,
    ) async {
      await pumpSheet(tester, (c, s) => _edit(s, 'Les dengan Pak Lana'));
      await enterTextAt(tester, 0, 'Nonton film bersama');
      await tapText(tester, 'Ganti');
      await tapText(tester, 'Nonton');
      await enterTextAt(tester, 1, 'Pak Lana sedang sakit.');
      await tapText(tester, 'Lihat tampilan Dulu → Sekarang di HP Rafi');

      expect(find.text('Dulu'), findsOneWidget);
      expect(find.text('Sekarang'), findsOneWidget);
      expect(find.text('Les'), findsOneWidget);
      expect(find.text('Nonton film'), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowRight), findsOneWidget);
      expect(find.text('Pak Lana sedang sakit.'), findsWidgets);
      expect(find.textContaining('Pesan dari'), findsNothing);
      expect(find.textContaining('Format tenang'), findsNothing);

      final dulu = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('Dulu'), matching: find.byType(Opacity))
            .first,
      );
      expect(dulu.opacity, 0.6);
    });
  });
}
