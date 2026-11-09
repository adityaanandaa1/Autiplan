// Tes domain logic completeActivity (HANDOFF §8.10)
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('completeActivity', () {
    final rafi = const Child(
      id: 'c1',
      name: 'Rafi',
      fullName: 'Rafi Ramadhan',
      age: 12,
      theme: ChildTheme.lautTenang,
      likes: [],
      avoids: [],
    );

    final sepeda = Activity(
      id: 'a1',
      childId: rafi.id,
      title: 'Sepeda Santai',
      shortTitle: 'Sepeda',
      icon: ActivityIcon.sepeda,
      date: DateTime(2026, 5, 1),
      start: const TimeOfDayLite(16, 0),
      end: const TimeOfDayLite(17, 0),
      steps: const ['Pakai helm', 'Bersepeda', 'Parkir sepeda'],
    );

    test('onTime=true bila selesai sebelum end', () {
      final state = AppState(
        children: [rafi],
        activities: [sepeda],
        completions: const [],
        notices: const [],
        notifications: const [],
        suggestionStatus: const {},
        settings: const Settings(),
      );

      final now = DateTime(2026, 5, 1, 16, 50); // 10 menit sebelum akhir
      final result = completeActivity(
        state: state,
        activity: sepeda,
        stepsChecked: const [true, true, true],
        now: now,
        completionId: 'comp1',
        notificationId: 'notif1',
      );

      expect(result.completion.onTime, true);
      expect(result.completion.activityId, sepeda.id);
      expect(result.completion.completedAt, now);
      expect(result.completion.stepsChecked, [true, true, true]);
      expect(result.state.completions.length, 1);
      expect(result.state.notifications.length, 1);
      expect(
        result.state.notifications.first.text,
        'Rafi menyelesaikan Sepeda Santai',
      );
      expect(
        result.state.notifications.first.type,
        NotificationType.activityDone,
      );
    });

    test('onTime=false bila selesai setelah end', () {
      final state = AppState(
        children: [rafi],
        activities: [sepeda],
        completions: const [],
        notices: const [],
        notifications: const [],
        suggestionStatus: const {},
        settings: const Settings(),
      );

      final now = DateTime(2026, 5, 1, 17, 5); // 5 menit setelah akhir
      final result = completeActivity(
        state: state,
        activity: sepeda,
        stepsChecked: const [true, false, true],
        now: now,
        completionId: 'comp2',
        notificationId: 'notif2',
      );

      expect(result.completion.onTime, false);
      expect(result.completion.stepsChecked, [true, false, true]);
    });

    test('onTime=true bila end=null (Tidur)', () {
      final tidur = Activity(
        id: 'a2',
        childId: rafi.id,
        title: 'Tidur',
        shortTitle: 'Tidur',
        icon: ActivityIcon.tidur,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(21, 0),
        end: null,
        steps: const ['Sikat gigi', 'Tidur'],
      );

      final state = AppState(
        children: [rafi],
        activities: [tidur],
        completions: const [],
        notices: const [],
        notifications: const [],
        suggestionStatus: const {},
        settings: const Settings(),
      );

      final now = DateTime(2026, 5, 1, 23, 0); // kapan saja
      final result = completeActivity(
        state: state,
        activity: tidur,
        stepsChecked: const [true, true],
        now: now,
        completionId: 'comp3',
        notificationId: 'notif3',
      );

      expect(result.completion.onTime, true);
    });

    test('stepsChecked kosong bila tanpa langkah', () {
      final makan = Activity(
        id: 'a3',
        childId: rafi.id,
        title: 'Makan',
        shortTitle: 'Makan',
        icon: ActivityIcon.makan,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(12, 0),
        end: const TimeOfDayLite(13, 0),
        steps: const [],
      );

      final state = AppState(
        children: [rafi],
        activities: [makan],
        completions: const [],
        notices: const [],
        notifications: const [],
        suggestionStatus: const {},
        settings: const Settings(),
      );

      final now = DateTime(2026, 5, 1, 12, 30);
      final result = completeActivity(
        state: state,
        activity: makan,
        stepsChecked: const [],
        now: now,
        completionId: 'comp4',
        notificationId: 'notif4',
      );

      expect(result.completion.stepsChecked, isEmpty);
      expect(result.completion.onTime, true);
    });
  });
}
