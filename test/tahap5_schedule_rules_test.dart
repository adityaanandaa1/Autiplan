import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:flutter_test/flutter_test.dart';

Activity _act({
  String id = 'x',
  ActivityIcon icon = ActivityIcon.main,
  required TimeOfDayLite start,
  TimeOfDayLite? end,
}) => Activity(
  id: id,
  childId: 'child-rafi',
  title: 'Uji',
  shortTitle: 'Uji',
  icon: icon,
  date: DateTime(2026, 5, 1),
  start: start,
  end: end,
);

void main() {
  group('validateTimeRange (§8.6)', () {
    test('Selesai harus setelah Mulai', () {
      expect(
        validateTimeRange(
          icon: ActivityIcon.main,
          start: const TimeOfDayLite(17, 0),
          end: const TimeOfDayLite(16, 0),
        ),
        TimeRangeIssue.endNotAfterStart,
      );
      expect(
        validateTimeRange(
          icon: ActivityIcon.main,
          start: const TimeOfDayLite(17, 0),
          end: const TimeOfDayLite(17, 0),
        ),
        TimeRangeIssue.endNotAfterStart,
      );
      expect(
        validateTimeRange(
          icon: ActivityIcon.main,
          start: const TimeOfDayLite(17, 0),
          end: const TimeOfDayLite(17, 1),
        ),
        isNull,
      );
    });

    test('end null hanya boleh untuk ikon Tidur', () {
      expect(
        validateTimeRange(
          icon: ActivityIcon.tidur,
          start: const TimeOfDayLite(21, 0),
        ),
        isNull,
      );
      expect(
        validateTimeRange(
          icon: ActivityIcon.main,
          start: const TimeOfDayLite(21, 0),
        ),
        TimeRangeIssue.endRequired,
      );
    });
  });

  group('hasConflict dengan rentang tidak valid', () {
    test(
      'Selesai < Mulai tidak membuat bentrok palsu dengan kegiatan lain',
      () {
        // 17.00 – 16.00 (terbalik) dianggap berdurasi bawaan 30 menit.
        final bad = _act(
          id: 'a',
          start: const TimeOfDayLite(17, 0),
          end: const TimeOfDayLite(16, 0),
        );
        final farAway = _act(
          id: 'b',
          start: const TimeOfDayLite(16, 10),
          end: const TimeOfDayLite(16, 50),
        );
        final overlapping = _act(
          id: 'c',
          start: const TimeOfDayLite(17, 10),
          end: const TimeOfDayLite(17, 40),
        );
        expect(hasConflict(bad, farAway), isFalse);
        expect(hasConflict(bad, overlapping), isTrue);
      },
    );
  });

  group('applyActivityEdit menolak waktu tidak valid', () {
    final state = buildFixtureState();
    final les = state.activities.firstWhere(
      (a) => a.title == 'Les dengan Pak Lana',
    );

    test('Selesai <= Mulai melempar ArgumentError', () {
      expect(
        () => applyActivityEdit(
          state: state,
          updated: les.copyWith(end: const TimeOfDayLite(19, 0)),
          message: 'Pesan',
          now: fixtureNow,
          noticeId: 'n',
        ),
        throwsArgumentError,
      );
    });

    test('end null untuk ikon selain Tidur melempar ArgumentError', () {
      expect(
        () => applyActivityEdit(
          state: state,
          updated: les.copyWith(clearEnd: true),
          message: 'Pesan',
          now: fixtureNow,
          noticeId: 'n',
        ),
        throwsArgumentError,
      );
    });

    test('Tidur dengan end null tetap boleh', () {
      final tidur = state.activities.firstWhere(
        (a) => a.icon == ActivityIcon.tidur && a.childId == les.childId,
      );
      final result = applyActivityEdit(
        state: state,
        updated: tidur.copyWith(steps: ['Satu']),
        message: null,
        now: fixtureNow,
        noticeId: 'n',
      );
      expect(result.notice, isNull);
    });
  });

  group('findShortGapBefore (§8.5 teks bantu)', () {
    final state = buildFixtureState();
    final all = state.activities;

    test('Mulai 17.05 setelah Sepeda Santai selesai 17.00: jeda 5 menit', () {
      final candidate = _act(
        id: 'new',
        start: const TimeOfDayLite(17, 5),
        end: const TimeOfDayLite(17, 35),
      );
      final r = findShortGapBefore(
        activity: candidate,
        allActivities: all,
        minGapMinutes: 10,
      );
      expect(r, isNotNull);
      expect(r!.previous.title, 'Sepeda Santai');
      expect(r.gap, 5);
    });

    test('Jeda 15 menit tidak memicu teks bantu', () {
      final candidate = _act(
        id: 'new',
        start: const TimeOfDayLite(17, 15),
        end: const TimeOfDayLite(17, 45),
      );
      expect(
        findShortGapBefore(
          activity: candidate,
          allActivities: all,
          minGapMinutes: 10,
        ),
        isNull,
      );
    });

    test('Bentrok (jeda negatif) tidak dihitung sebagai jeda pendek', () {
      final candidate = _act(
        id: 'new',
        start: const TimeOfDayLite(16, 30),
        end: const TimeOfDayLite(17, 15),
      );
      expect(
        findShortGapBefore(
          activity: candidate,
          allActivities: all,
          minGapMinutes: 10,
        ),
        isNull,
      );
    });
  });
}
