import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_repository.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/domain/recurrence.dart';
import 'package:autiplan/domain/schedule_rules.dart';

Activity _occurrence(
  DateTime date, {
  String seriesId = 's1',
  String? id,
  String title = 'Sekolah',
  String? replacedTitle,
  Set<int> weekdays = const {1, 2, 3, 4, 5},
}) {
  final stamp =
      '${date.year}${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';
  return Activity(
    id: id ?? '${seriesId}_$stamp',
    childId: 'c1',
    title: title,
    shortTitle: title,
    icon: ActivityIcon.sekolah,
    date: date,
    start: const TimeOfDayLite(7, 0),
    end: const TimeOfDayLite(12, 0),
    repeatWeekdays: weekdays,
    seriesId: seriesId,
    replacedTitle: replacedTitle,
  );
}

List<DateTime> _dates(Iterable<Activity> list) =>
    list.map((a) => a.date).toList();

void main() {
  final monday = DateTime(2026, 11, 2);

  group('materializeRecurring', () {
    test('seri Sen-Jum dari Senin, horizon 7 hari -> 3,4,5,6,9 Nov', () {
      final result = materializeRecurring(
        [_occurrence(monday)],
        monday,
        horizonDays: 7,
      );
      expect(_dates(result.skip(1)), [
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 5),
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 9),
      ]);
      expect(result[1].id, 's1_20261103');
      expect(result.every((a) => a.seriesId == 's1'), isTrue);
    });

    test('dijalankan dua kali menghasilkan daftar yang sama persis', () {
      final once = materializeRecurring(
        [_occurrence(monday)],
        monday,
        horizonDays: 7,
      );
      final twice = materializeRecurring(once, monday, horizonDays: 7);
      expect(twice, once);
    });

    test('seriesId null tidak menambah apa pun', () {
      final plain = _occurrence(monday).copyWith(clearSeriesId: true);
      final result = materializeRecurring([plain], monday, horizonDays: 7);
      expect(result, [plain]);
    });

    test('kemunculan tengah yang dihapus tidak muncul lagi', () {
      final full = materializeRecurring(
        [_occurrence(monday)],
        monday,
        horizonDays: 7,
      );
      final withoutWednesday = full
          .where((a) => a.date != DateTime(2026, 11, 4))
          .toList();
      final again = materializeRecurring(
        withoutWednesday,
        monday,
        horizonDays: 7,
      );
      expect(again.any((a) => a.date == DateTime(2026, 11, 4)), isFalse);
      expect(again.length, withoutWednesday.length);
    });

    test('kemunculan terakhir diganti nama: salinan baru memakai judul '
        'kemunculan sebelumnya', () {
      final list = [
        _occurrence(monday),
        _occurrence(
          DateTime(2026, 11, 3),
          title: 'Sekolah khusus',
          replacedTitle: 'Sekolah',
        ),
      ];
      final result = materializeRecurring(list, monday, horizonDays: 7);
      final added = result.skip(2).toList();
      expect(added, isNotEmpty);
      expect(added.every((a) => a.title == 'Sekolah'), isTrue);
      expect(added.every((a) => a.replacedTitle == null), isTrue);
    });

    test('seri yang lama tidak dibuka tidak diisi mundur ke masa lalu', () {
      final result = materializeRecurring(
        [_occurrence(monday)],
        DateTime(2026, 11, 16),
        horizonDays: 1,
      );
      expect(_dates(result.skip(1)), [
        DateTime(2026, 11, 16),
        DateTime(2026, 11, 17),
      ]);
    });

    test('salinan tetap cocok dengan pencocokan streak', () {
      final result = materializeRecurring(
        [_occurrence(monday)],
        monday,
        horizonDays: 7,
      );
      final completions = [
        for (final a in result.take(2))
          Completion(
            activityId: a.id,
            date: a.date,
            completedAt: a.date,
            onTime: true,
            stepsChecked: const [],
          ),
      ];
      final dates = consecutiveOnTimeDates(
        activity: result[2],
        referenceDate: result[2].date,
        allActivities: result,
        completions: completions,
      );
      expect(dates, [DateTime(2026, 11, 3), DateTime(2026, 11, 2)]);
    });
  });

  group('applyRepeatChange', () {
    List<Activity> series() =>
        materializeRecurring([_occurrence(monday)], monday, horizonDays: 7);

    test('hari kosong menghapus semua kemunculan setelah tanggal itu, '
        'kemunculan itu tetap', () {
      final all = series();
      final edited = all[2].copyWith(repeatWeekdays: <int>{}); // 4 Nov
      final result = applyRepeatChange(all, edited);
      expect(_dates(result), [
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
      ]);
      expect(result.last.repeatWeekdays, isEmpty);
    });

    test('tidak menyentuh kemunculan sebelum tanggal itu', () {
      final all = series();
      final edited = all[3].copyWith(repeatWeekdays: {6}); // 5 Nov
      final result = applyRepeatChange(all, edited);
      expect(result.take(3).toList(), all.take(3).toList());
      expect(result[3].repeatWeekdays, {6});
      expect(result.length, 4);
    });

    test('hari ulang baru dipakai saat salinan berikutnya dibuat', () {
      final all = series();
      final edited = all[3].copyWith(
        repeatWeekdays: {6},
        title: 'Sekolah khusus',
        replacedTitle: 'Sekolah',
      );
      final changed = applyRepeatChange(all, edited);
      final result = materializeRecurring(
        changed,
        DateTime(2026, 11, 5),
        horizonDays: 10,
      );
      final added = result.skip(changed.length).toList();
      expect(_dates(added), [DateTime(2026, 11, 7), DateTime(2026, 11, 14)]);
      expect(added.every((a) => a.title == 'Sekolah'), isTrue);
    });

    test('kegiatan tanpa seriesId yang diberi hari ulang memulai seri '
        'baru', () {
      final plain = _occurrence(
        monday,
        id: 'act-1',
      ).copyWith(clearSeriesId: true, repeatWeekdays: {1});
      final result = applyRepeatChange([plain], plain);
      expect(result.single.seriesId, 'act-1');
    });
  });

  group('Activity.seriesId', () {
    test('masuk toJson, fromJson, ==, hashCode, copyWith', () {
      final a = _occurrence(monday);
      expect(Activity.fromJson(a.toJson()), a);
      expect(Activity.fromJson(a.toJson()).seriesId, 's1');
      expect(a.copyWith(seriesId: 's2'), isNot(a));
      expect(a.copyWith(seriesId: 's2').hashCode, isNot(a.hashCode));
      expect(a.copyWith(clearSeriesId: true).seriesId, isNull);
    });

    test('dokumen lama tanpa seriesId terbaca dengan nilai null', () {
      final json = _occurrence(monday).toJson()..remove('seriesId');
      expect(Activity.fromJson(json).seriesId, isNull);
    });
  });

  group('AppStateNotifier normalize', () {
    late InMemoryRepository repo;

    setUp(() => repo = InMemoryRepository());

    AppState stateWith(List<Activity> activities) =>
        AppState.empty().copyWith(activities: activities);

    test('updateState memperluas seri lewat normalize', () {
      final notifier = AppStateNotifier(
        repo,
        AppState.empty(),
        normalize: (s) =>
            s.copyWith(activities: materializeRecurring(s.activities, monday)),
      );
      notifier.updateState(stateWith([_occurrence(monday)]));
      expect(notifier.state.activities.length, greaterThan(15));
    });

    test('state awal ikut dinormalkan; tanpa normalize apa adanya', () {
      final withNorm = AppStateNotifier(
        repo,
        stateWith([_occurrence(monday)]),
        normalize: (s) =>
            s.copyWith(activities: materializeRecurring(s.activities, monday)),
      );
      expect(withNorm.state.activities.length, greaterThan(15));
      final plain = AppStateNotifier(repo, stateWith([_occurrence(monday)]));
      expect(plain.state.activities.length, 1);
    });

    test('renormalize memperluas seri saat hari berganti', () {
      var today = monday;
      final notifier = AppStateNotifier(
        repo,
        stateWith([_occurrence(monday)]),
        normalize: (s) => s.copyWith(
          activities: materializeRecurring(s.activities, today, horizonDays: 3),
        ),
      );
      final before = notifier.state.activities.length;
      today = DateTime(2026, 12, 7);
      notifier.renormalize();
      expect(notifier.state.activities.length, greaterThan(before));
    });
  });
}
