import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/seed.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schedule Rules — Status dan Progres (Test 1–2)', () {
    late AppState state;
    late DateTime now;

    setUp(() {
      state = buildSeedState();
      now = Clock.demoTime; // Jumat 1 Mei 2026 16.00
    });

    test(
      'Test 1: Status — Sekolah Selesai, Sepeda Sekarang, sisanya Biasa',
      () {
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
        final friday = DateTime(2026, 5, 1);

        final rafiActivities = state.activities
            .where(
              (a) =>
                  a.childId == rafi.id &&
                  a.date.year == friday.year &&
                  a.date.month == friday.month &&
                  a.date.day == friday.day,
            )
            .toList();

        final sekolah = rafiActivities.firstWhere((a) => a.title == 'Sekolah');
        final sepeda = rafiActivities.firstWhere(
          (a) => a.title == 'Sepeda Santai',
        );
        final ngaji = rafiActivities.firstWhere(
          (a) => a.title == 'Ngaji di Rumah',
        );
        final les = rafiActivities.firstWhere(
          (a) => a.title == 'Les dengan Pak Lana',
        );

        final sekolahStatus = getActivityStatus(
          activity: sekolah,
          selectedDate: friday,
          now: now,
          completions: state.completions,
          notices: state.notices,
        );
        expect(sekolahStatus.status, ActivityStatus.selesai);

        final sepedaStatus = getActivityStatus(
          activity: sepeda,
          selectedDate: friday,
          now: now,
          completions: state.completions,
          notices: state.notices,
        );
        expect(sepedaStatus.status, ActivityStatus.sekarang);
        expect(sepedaStatus.isNow, isTrue);

        final ngajiStatus = getActivityStatus(
          activity: ngaji,
          selectedDate: friday,
          now: now,
          completions: state.completions,
          notices: state.notices,
        );
        expect(ngajiStatus.status, ActivityStatus.biasa);

        final lesStatus = getActivityStatus(
          activity: les,
          selectedDate: friday,
          now: now,
          completions: state.completions,
          notices: state.notices,
        );
        expect(lesStatus.status, ActivityStatus.biasa);
      },
    );

    test('Test 1: Progres Rafi 1/5, Atalia 2/3', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final atalia = state.children.firstWhere((c) => c.name == 'Atalia');
      final friday = DateTime(2026, 5, 1);

      final rafiProgress = calculateProgress(
        childId: rafi.id,
        date: friday,
        activities: state.activities,
        completions: state.completions,
      );
      expect(rafiProgress.$1, 1); // selesai
      expect(rafiProgress.$2, 5); // total

      final ataliaProgress = calculateProgress(
        childId: atalia.id,
        date: friday,
        activities: state.activities,
        completions: state.completions,
      );
      expect(ataliaProgress.$1, 2);
      expect(ataliaProgress.$2, 3);
    });

    test('Kegiatan tanpa end: Sekarang hanya bila now >= start (§8.1)', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final tidur = Activity(
        id: 'test-tidur',
        childId: rafi.id,
        title: 'Tidur',
        shortTitle: 'Tidur',
        icon: ActivityIcon.tidur,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(21, 0),
      );
      ActivityStatusResult at(DateTime t) => getActivityStatus(
        activity: tidur,
        selectedDate: DateTime(2026, 5, 1),
        now: t,
        completions: const [],
        notices: const [],
      );
      expect(at(DateTime(2026, 5, 1, 16, 0)).isNow, isFalse);
      expect(at(DateTime(2026, 5, 1, 22, 0)).isNow, isTrue);
      expect(at(DateTime(2026, 5, 1, 22, 0)).status, ActivityStatus.sekarang);
    });

    test('formatDateRange: satu bulan dan beda bulan', () {
      expect(
        formatDateRange(DateTime(2026, 4, 24), DateTime(2026, 4, 30)),
        '24–30 April',
      );
      expect(
        formatDateRange(DateTime(2026, 4, 28), DateTime(2026, 5, 2)),
        '28 April–2 Mei',
      );
    });
  });
}
