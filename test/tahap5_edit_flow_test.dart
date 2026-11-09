import 'package:autiplan/core/widgets/buttons.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/features/caregiver/widgets/edit_activity_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tahap5_helpers.dart';

PrimaryButton _button(WidgetTester tester, String label) =>
    tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, label));

Widget _editLes(BuildContext ctx, AppState s) => EditActivitySheet(
  activity: activityTitled(s, 'Les dengan Pak Lana'),
  child: rafiOf(s),
);

void main() {
  group('Bug 1: Urungkan setelah hapus (§8.8, alur 13.3)', () {
    testWidgets(
      'hapus lalu Urungkan mengembalikan kegiatan dan menghapus notice',
      (tester) async {
        final host = await pumpSheet(tester, _editLes);
        final before = host.state;

        await tapText(tester, 'Hapus kegiatan');
        await tapText(tester, 'Hapus jadwal');

        expect(
          host.state.activities.any((a) => a.title == 'Les dengan Pak Lana'),
          isFalse,
        );
        expect(host.state.notices.length, before.notices.length + 1);
        expect(find.text('Les dengan Pak Lana dihapus'), findsOneWidget);

        await tester.tap(find.text('Urungkan'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(host.state.activities, before.activities);
        expect(host.state.notices, before.notices);
      },
    );
  });

  group('Alur 13.1 langkah 1-3', () {
    testWidgets('ubah nama + ikon, pesan wajib, kirim; shortTitle ikut nama', (
      tester,
    ) async {
      final host = await pumpSheet(tester, _editLes);

      // OT-10: catatan + tombol nonaktif.
      expect(
        find.text(
          'Kolom "Pesan untuk Rafi" muncul setelah kamu mengubah nama, ikon, atau jam.',
        ),
        findsOneWidget,
      );
      expect(_button(tester, 'Kirim perubahan').enabled, isFalse);

      await enterTextAt(tester, 0, 'Nonton film bersama');
      await tapText(tester, 'Ganti');
      await tapText(tester, 'Nonton');

      // OT-11: kolom pesan + penghitung; tombol masih nonaktif tanpa pesan.
      expect(find.text('Pesan untuk Rafi'), findsOneWidget);
      expect(find.text('0/120'), findsOneWidget);
      expect(_button(tester, 'Kirim perubahan').enabled, isFalse);

      // Kartu saran kontekstual (§8.7).
      expect(
        find.textContaining('selesai 15 menit sebelum tidur'),
        findsWidgets,
      );

      await enterTextAt(
        tester,
        1,
        'Pak Lana sedang sakit. Kita nonton film dulu supaya kamu santai sebelum tidur.',
      );
      expect(_button(tester, 'Kirim perubahan').enabled, isTrue);

      await tester.ensureVisible(
        find.widgetWithText(PrimaryButton, 'Kirim perubahan'),
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'Kirim perubahan'));
      await tester.pumpAndSettle();

      final saved = host.state.activities.firstWhere(
        (a) => a.title == 'Nonton film bersama',
      );
      expect(saved.icon, ActivityIcon.nonton);
      expect(saved.shortTitle, 'Nonton film');
      expect(saved.replacedTitle, 'Les dengan Pak Lana');
      expect(host.state.notices, hasLength(1));
      expect(host.state.notices.single.before.shortTitle, 'Les');
      expect(host.state.notices.single.seenAt, isNull);
      expect(find.text('Perubahan terkirim ke Rafi'), findsOneWidget);
    });

    testWidgets('mengubah mode mandiri saja: tombol "Simpan", tanpa notice', (
      tester,
    ) async {
      final host = await pumpSheet(tester, _editLes);
      expect(find.widgetWithText(PrimaryButton, 'Simpan'), findsNothing);
      await tapText(tester, 'Langkah & pengulangan');
      await tapText(tester, 'Mode mandiri');
      expect(_button(tester, 'Simpan').enabled, isTrue);
      expect(find.text('Kirim perubahan'), findsNothing);
      expect(find.text('Pesan untuk Rafi'), findsNothing);

      await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Simpan'));
      await tester.tap(find.widgetWithText(PrimaryButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(host.state.notices, isEmpty);
      expect(
        activityTitled(host.state, 'Les dengan Pak Lana').independentMode,
        isTrue,
      );
    });
  });

  group('Bug 2: shortTitle', () {
    testWidgets('ubah opsi lanjutan saja mempertahankan shortTitle seed', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (ctx, s) => EditActivitySheet(
          activity: activityTitled(s, 'Sepeda Santai'),
          child: rafiOf(s),
        ),
      );
      await tapText(tester, 'Langkah & pengulangan');
      await tapText(tester, 'Mode mandiri');
      await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'Simpan'));
      await tester.tap(find.widgetWithText(PrimaryButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(activityTitled(host.state, 'Sepeda Santai').shortTitle, 'Sepeda');
    });
  });
}
