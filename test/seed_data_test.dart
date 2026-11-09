import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Seed Data Specification (HANDOFF Bagian 7)', () {
    late AppState state;

    setUp(() {
      state = buildFixtureState();
    });

    test('7.2 Anak: berisi Rafi dan Atalia dengan profil yang tepat', () {
      expect(state.children.length, 2);

      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      expect(rafi.fullName, 'Rafi Ramadhan');
      expect(rafi.age, 12);
      expect(rafi.theme, ChildTheme.lautTenang);
      expect(rafi.likes, containsAll(['Bersepeda', 'Film animasi']));
      expect(rafi.avoids, containsAll(['Suara keras', 'Tempat ramai']));

      final atalia = state.children.firstWhere((c) => c.name == 'Atalia');
      expect(atalia.fullName, 'Atalia Putri');
      expect(atalia.age, 9);
      expect(atalia.theme, ChildTheme.padangHijau);
      expect(atalia.likes, contains('Puzzle'));
      expect(atalia.avoids, contains('Suara keras'));
    });

    test('7.3 Kegiatan Rafi pada Jumat 1 Mei 2026 persis 5 kegiatan', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final may1 = DateTime(2026, 5, 1);

      final rafiMay1Activities = state.activities
          .where(
            (a) =>
                a.childId == rafi.id &&
                a.date.year == may1.year &&
                a.date.month == may1.month &&
                a.date.day == may1.day,
          )
          .toList();

      expect(rafiMay1Activities.length, 5);

      final titles = rafiMay1Activities.map((a) => a.title).toList();
      expect(
        titles,
        containsAll([
          'Sekolah',
          'Sepeda Santai',
          'Ngaji di Rumah',
          'Les dengan Pak Lana',
          'Istirahat & Tidur Malam',
        ]),
      );

      // Detail per kegiatan
      final sekolah = rafiMay1Activities.firstWhere(
        (a) => a.title == 'Sekolah',
      );
      expect(sekolah.shortTitle, 'Sekolah');
      expect(sekolah.icon, ActivityIcon.sekolah);
      expect(sekolah.start, const TimeOfDayLite(7, 0));
      expect(sekolah.end, const TimeOfDayLite(8, 0));
      expect(sekolah.steps.length, 4);
      expect(sekolah.repeatWeekdays, {1, 2, 3, 4, 5});

      final sepeda = rafiMay1Activities.firstWhere(
        (a) => a.title == 'Sepeda Santai',
      );
      expect(sepeda.shortTitle, 'Sepeda');
      expect(sepeda.icon, ActivityIcon.sepeda);
      expect(sepeda.start, const TimeOfDayLite(16, 0));
      expect(sepeda.end, const TimeOfDayLite(17, 0));
      expect(sepeda.steps.length, 3);

      final ngaji = rafiMay1Activities.firstWhere(
        (a) => a.title == 'Ngaji di Rumah',
      );
      expect(ngaji.shortTitle, 'Ngaji');
      expect(ngaji.icon, ActivityIcon.ngaji);
      expect(ngaji.start, const TimeOfDayLite(18, 0));
      expect(ngaji.end, const TimeOfDayLite(19, 0));

      final les = rafiMay1Activities.firstWhere(
        (a) => a.title == 'Les dengan Pak Lana',
      );
      expect(les.shortTitle, 'Les');
      expect(les.icon, ActivityIcon.les);
      expect(les.start, const TimeOfDayLite(20, 0));
      expect(les.end, const TimeOfDayLite(20, 45));
      expect(les.repeatWeekdays, {5});

      final tidur = rafiMay1Activities.firstWhere(
        (a) => a.title == 'Istirahat & Tidur Malam',
      );
      expect(tidur.shortTitle, 'Tidur');
      expect(tidur.icon, ActivityIcon.tidur);
      expect(tidur.start, const TimeOfDayLite(21, 0));
      expect(tidur.end, isNull);
    });

    test(
      '7.3 Riwayat kegiatan dan completion Sepeda Santai 5 kali berturut-turut',
      () {
        final dates = [
          DateTime(2026, 4, 24),
          DateTime(2026, 4, 27),
          DateTime(2026, 4, 28),
          DateTime(2026, 4, 29),
          DateTime(2026, 4, 30),
        ];

        for (final date in dates) {
          final comp = state.completions.where(
            (c) =>
                c.date.year == date.year &&
                c.date.month == date.month &&
                c.date.day == date.day &&
                c.activityId.startsWith('rafi-sepeda'),
          );
          expect(comp.isNotEmpty, isTrue);
          expect(comp.first.onTime, isTrue);
          expect(comp.first.completedAt.hour, 16);
          expect(comp.first.completedAt.minute, 50);
        }
      },
    );

    test('7.4 Kegiatan Atalia pada Jumat 1 Mei 2026 ada 3 kegiatan', () {
      final atalia = state.children.firstWhere((c) => c.name == 'Atalia');
      final may1 = DateTime(2026, 5, 1);

      final ataliaActivities = state.activities
          .where(
            (a) =>
                a.childId == atalia.id &&
                a.date.year == may1.year &&
                a.date.month == may1.month &&
                a.date.day == may1.day,
          )
          .toList();

      expect(ataliaActivities.length, 3);
      final titles = ataliaActivities.map((a) => a.title).toList();
      expect(
        titles,
        containsAll(['Sekolah TK B', 'Makan Siang Bersama', 'Bermain Puzzle']),
      );
    });

    test('7.5 Notifikasi awal ada 3 sesuai spesifikasi', () {
      expect(state.notifications.length, 3);

      final types = state.notifications.map((n) => n.type).toList();
      expect(
        types,
        containsAll([
          NotificationType.activityDone,
          NotificationType.emergencyPressed,
          NotificationType.activityStarted,
        ]),
      );

      final emergency = state.notifications.firstWhere(
        (n) => n.type == NotificationType.emergencyPressed,
      );
      expect(emergency.badge, 'Sudah ditelepon');
    });

    test('7.6 Tidak ada ChangeNotice di awal (seed)', () {
      expect(state.notices, isEmpty);
    });
  });
}
