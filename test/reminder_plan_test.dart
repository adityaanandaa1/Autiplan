import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/domain/reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

const _child = Child(
  id: 'c1',
  name: 'Dimas',
  fullName: 'Dimas Putra',
  age: 10,
  theme: ChildTheme.lautTenang,
  likes: [],
  avoids: [],
);

Activity _activity(String id, DateTime date, int hour, int minute) => Activity(
  id: id,
  childId: 'c1',
  title: 'Makan siang',
  shortTitle: 'Makan',
  icon: ActivityIcon.makan,
  date: date,
  start: TimeOfDayLite(hour, minute),
);

AppState _state(List<Activity> acts, {List<Completion> done = const []}) =>
    AppState.empty().copyWith(
      children: [_child],
      activities: acts,
      completions: done,
    );

void main() {
  final today = DateTime(2026, 5, 1);
  final now = DateTime(2026, 5, 1, 12, 0);

  test('kegiatan 16.00 dengan pengingat 15 menit dijadwalkan 15.45', () {
    final plan = planReminders(_state([_activity('a', today, 16, 0)]), now);
    expect(plan, hasLength(1));
    expect(plan.single.activityId, 'a');
    expect(plan.single.at, DateTime(2026, 5, 1, 15, 45));
    expect(plan.single.body, 'Makan siang untuk Dimas mulai 15 menit lagi.');
  });

  test('waktu pengingat yang sudah lewat dilewati', () {
    final plan = planReminders(_state([_activity('a', today, 11, 50)]), now);
    expect(plan, isEmpty);
  });

  test('kegiatan yang sudah selesai dilewati', () {
    final state = _state(
      [_activity('a', today, 16, 0)],
      done: [
        Completion(
          activityId: 'a',
          date: today,
          completedAt: DateTime(2026, 5, 1, 11, 0),
          onTime: true,
          stepsChecked: const [],
        ),
      ],
    );
    expect(planReminders(state, now), isEmpty);
  });

  test('hasil urut paling awal dan dibatasi maxCount', () {
    final acts = [
      for (var i = 0; i < 60; i++)
        _activity('a$i', today.add(Duration(days: i % 20)), 16 - (i % 3), 0),
    ];
    final plan = planReminders(_state(acts), now);
    expect(plan, hasLength(50));
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
    }
    expect(planReminders(_state(acts), now, maxCount: 3), hasLength(3));
  });
}
