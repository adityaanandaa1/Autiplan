import 'dart:convert';

import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppState Serialization (Test 13 Bagian 16)', () {
    test('AppState -> JSON -> AppState menghasilkan objek yang identik', () {
      final original = buildFixtureState();

      // Encode to JSON string
      final jsonMap = original.toJson();
      final jsonString = jsonEncode(jsonMap);

      // Decode back from JSON string
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = AppState.fromJson(decodedMap);

      // 1. Children
      expect(restored.children.length, original.children.length);
      for (var i = 0; i < original.children.length; i++) {
        final orig = original.children[i];
        final rest = restored.children[i];
        expect(rest.id, orig.id);
        expect(rest.name, orig.name);
        expect(rest.fullName, orig.fullName);
        expect(rest.age, orig.age);
        expect(rest.theme, orig.theme);
        expect(rest.likes, orig.likes);
        expect(rest.avoids, orig.avoids);
      }

      // 2. Activities
      expect(restored.activities.length, original.activities.length);
      for (var i = 0; i < original.activities.length; i++) {
        final orig = original.activities[i];
        final rest = restored.activities[i];
        expect(rest.id, orig.id);
        expect(rest.childId, orig.childId);
        expect(rest.title, orig.title);
        expect(rest.shortTitle, orig.shortTitle);
        expect(rest.icon, orig.icon);
        expect(rest.date.year, orig.date.year);
        expect(rest.date.month, orig.date.month);
        expect(rest.date.day, orig.date.day);
        expect(rest.start, orig.start);
        expect(rest.end, orig.end);
        expect(rest.steps, orig.steps);
        expect(rest.repeatWeekdays, orig.repeatWeekdays);
        expect(rest.usesScreen, orig.usesScreen);
        expect(rest.independentMode, orig.independentMode);
        expect(rest.replacedTitle, orig.replacedTitle);
      }

      // 3. Completions
      expect(restored.completions.length, original.completions.length);
      for (var i = 0; i < original.completions.length; i++) {
        final orig = original.completions[i];
        final rest = restored.completions[i];
        expect(rest.activityId, orig.activityId);
        expect(rest.date.year, orig.date.year);
        expect(rest.date.month, orig.date.month);
        expect(rest.date.day, orig.date.day);
        expect(rest.completedAt, orig.completedAt);
        expect(rest.onTime, orig.onTime);
        expect(rest.stepsChecked, orig.stepsChecked);
      }

      // 4. Change notices
      expect(restored.notices.length, original.notices.length);

      // 5. Notifications
      expect(restored.notifications.length, original.notifications.length);
      for (var i = 0; i < original.notifications.length; i++) {
        final orig = original.notifications[i];
        final rest = restored.notifications[i];
        expect(rest.id, orig.id);
        expect(rest.type, orig.type);
        expect(rest.text, orig.text);
        expect(rest.at, orig.at);
        expect(rest.read, orig.read);
        expect(rest.badge, orig.badge);
      }

      // 6. Suggestion status map
      expect(restored.suggestionStatus, original.suggestionStatus);

      // 7. Settings
      expect(
        restored.settings.reminderMinutesBefore,
        original.settings.reminderMinutesBefore,
      );
      expect(restored.settings.minGapMinutes, original.settings.minGapMinutes);
      expect(
        restored.settings.independenceStreakDays,
        original.settings.independenceStreakDays,
      );
      expect(
        restored.settings.quietTimeMinutes,
        original.settings.quietTimeMinutes,
      );
      expect(
        restored.settings.emergencyNumber,
        original.settings.emergencyNumber,
      );
      expect(restored.settings.backupNumber, original.settings.backupNumber);
      expect(restored.settings.caregiverName, original.settings.caregiverName);
    });

    test(
      'AppState berisi ChangeNotice dan status saran identik setelah round-trip',
      () {
        final base = buildFixtureState();
        const before = ActivitySnapshot(
          shortTitle: 'Les',
          title: 'Les dengan Pak Lana',
          icon: ActivityIcon.les,
          start: TimeOfDayLite(20, 0),
        );
        const after = ActivitySnapshot(
          shortTitle: 'Nonton',
          title: 'Nonton film',
          icon: ActivityIcon.nonton,
          start: TimeOfDayLite(20, 0),
        );
        final original = base.copyWith(
          notices: [
            ChangeNotice(
              id: 'n1',
              childId: 'child-rafi',
              activityId: 'rafi-les-20260501',
              before: before,
              after: after,
              message: 'Les diganti nonton film',
              sentAt: DateTime(2026, 5, 1, 16, 5),
              seenAt: DateTime(2026, 5, 1, 16, 10),
            ),
            ChangeNotice(
              id: 'n2',
              childId: 'child-rafi',
              activityId: 'rafi-ngaji-20260501',
              before: before,
              message: 'Ngaji hari ini tidak jadi.',
              sentAt: DateTime(2026, 5, 1, 16, 6),
            ),
          ],
          suggestionStatus: const {
            'independence:rafi-sepeda-20260501': SuggestionStatus.dismissed,
            'emptyDay:2026-05-02': SuggestionStatus.applied,
          },
        );

        final restored = AppState.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
        );

        expect(restored.notices[1].after, isNull);
        expect(restored.notices[0].seenAt, DateTime(2026, 5, 1, 16, 10));
        expect(restored, original);
        expect(restored.hashCode, original.hashCode);
      },
    );
  });
}
