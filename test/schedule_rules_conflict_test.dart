import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/seed.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schedule Rules — Urutan, Bentrok, Jeda (Test 2–4)', () {
    late AppState state;

    setUp(() {
      state = buildSeedState();
    });

    test(
      'Test 2: Urutan — kegiatan baru 17.15 masuk antara Sepeda dan Ngaji',
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

        final newActivity = Activity(
          id: 'test-new',
          childId: rafi.id,
          title: 'Kegiatan Baru',
          shortTitle: 'Baru',
          icon: ActivityIcon.main,
          date: friday,
          start: const TimeOfDayLite(17, 15),
          end: const TimeOfDayLite(17, 45),
        );

        final withNew = [...rafiActivities, newActivity];
        final sorted = sortActivitiesByStartTime(withNew);

        final titles = sorted.map((a) => a.title).toList();
        final sepedaIndex = titles.indexOf('Sepeda Santai');
        final newIndex = titles.indexOf('Kegiatan Baru');
        final ngajiIndex = titles.indexOf('Ngaji di Rumah');

        expect(newIndex, greaterThan(sepedaIndex));
        expect(newIndex, lessThan(ngajiIndex));
      },
    );

    test(
      'Test 3: Bentrok — 16.30–17.15 bentrok dengan Sepeda Santai 16.00–17.00',
      () {
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
        final friday = DateTime(2026, 5, 1);

        final sepeda = state.activities.firstWhere(
          (a) =>
              a.childId == rafi.id &&
              a.title == 'Sepeda Santai' &&
              a.date == friday,
        );

        final conflicting = Activity(
          id: 'test-conflict',
          childId: rafi.id,
          title: 'Mandi Sore',
          shortTitle: 'Mandi',
          icon: ActivityIcon.mandi,
          date: friday,
          start: const TimeOfDayLite(16, 30),
          end: const TimeOfDayLite(17, 15),
        );

        expect(hasConflict(sepeda, conflicting), isTrue);

        final allActivities = state.activities
            .where((a) => a.childId == rafi.id && a.date == friday)
            .toList();

        final conflicts = findConflicts(
          activity: conflicting,
          allActivities: allActivities,
        );
        expect(conflicts.length, 1);
        expect(conflicts.first.title, 'Sepeda Santai');
      },
    );

    test('Test 3: Slot terdekat — 17.10–17.55', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final friday = DateTime(2026, 5, 1);

      final sepeda = state.activities.firstWhere(
        (a) =>
            a.childId == rafi.id &&
            a.title == 'Sepeda Santai' &&
            a.date == friday,
      );

      final conflicting = Activity(
        id: 'test-slot',
        childId: rafi.id,
        title: 'Mandi Sore',
        shortTitle: 'Mandi',
        icon: ActivityIcon.mandi,
        date: friday,
        start: const TimeOfDayLite(16, 30),
        end: const TimeOfDayLite(17, 15),
      );

      final allActivities = state.activities
          .where((a) => a.childId == rafi.id && a.date == friday)
          .toList();

      final freeSlot = findNearestFreeSlot(
        activity: conflicting,
        allActivities: allActivities,
        conflictingActivity: sepeda,
      );

      expect(freeSlot, isNotNull);
      expect(freeSlot!.hour, 17);
      expect(freeSlot.minute, 10);
    });

    test('Bug C: slot terdekat memakai minGapMinutes 20 -> 17.20', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final friday = DateTime(2026, 5, 1);
      final sepeda = state.activities.firstWhere(
        (a) =>
            a.childId == rafi.id &&
            a.title == 'Sepeda Santai' &&
            a.date == friday,
      );
      final conflicting = Activity(
        id: 'test-slot-20',
        childId: rafi.id,
        title: 'Mandi Sore',
        shortTitle: 'Mandi',
        icon: ActivityIcon.mandi,
        date: friday,
        start: const TimeOfDayLite(16, 30),
        end: const TimeOfDayLite(17, 15),
      );
      final freeSlot = findNearestFreeSlot(
        activity: conflicting,
        // Hanya Sepeda: 17.20 + 45 menit bentrok dengan kegiatan 18.00 di seed
        allActivities: [sepeda],
        conflictingActivity: sepeda,
        minGapMinutes: 20,
      );
      expect(freeSlot, isNotNull);
      expect(freeSlot!.hour, 17);
      expect(freeSlot.minute, 20);
    });

    test('Test 3: 17.15–17.45 tidak bentrok', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final friday = DateTime(2026, 5, 1);

      final nonConflicting = Activity(
        id: 'test-no-conflict',
        childId: rafi.id,
        title: 'Kegiatan Aman',
        shortTitle: 'Aman',
        icon: ActivityIcon.main,
        date: friday,
        start: const TimeOfDayLite(17, 15),
        end: const TimeOfDayLite(17, 45),
      );

      final allActivities = state.activities
          .where((a) => a.childId == rafi.id && a.date == friday)
          .toList();

      final conflicts = findConflicts(
        activity: nonConflicting,
        allActivities: allActivities,
      );
      expect(conflicts, isEmpty);
    });

    test(
      'Test 4: Jeda — 17.00 setelah Sepeda selesai 17.00 memicu transitionGap (jeda 0)',
      () {
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
        final friday = DateTime(2026, 5, 1);

        final sepeda = state.activities.firstWhere(
          (a) =>
              a.childId == rafi.id &&
              a.title == 'Sepeda Santai' &&
              a.date == friday,
        );

        final immediate = Activity(
          id: 'test-immediate',
          childId: rafi.id,
          title: 'Kegiatan Langsung',
          shortTitle: 'Langsung',
          icon: ActivityIcon.main,
          date: friday,
          start: const TimeOfDayLite(17, 0),
          end: const TimeOfDayLite(17, 30),
        );

        final gap = calculateGapMinutes(sepeda, immediate);
        expect(gap, 0);
        expect(gap! < 10, isTrue); // minGapMinutes = 10
      },
    );

    test('Test 4: 17.15 tidak memicu (jeda 15 >= 10)', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final friday = DateTime(2026, 5, 1);

      final sepeda = state.activities.firstWhere(
        (a) =>
            a.childId == rafi.id &&
            a.title == 'Sepeda Santai' &&
            a.date == friday,
      );

      final safe = Activity(
        id: 'test-safe',
        childId: rafi.id,
        title: 'Kegiatan Aman',
        shortTitle: 'Aman',
        icon: ActivityIcon.main,
        date: friday,
        start: const TimeOfDayLite(17, 15),
        end: const TimeOfDayLite(17, 45),
      );

      final gap = calculateGapMinutes(sepeda, safe);
      expect(gap, 15);
      expect(gap! >= 10, isTrue);
    });
  });
}
