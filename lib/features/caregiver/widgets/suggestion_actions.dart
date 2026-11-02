import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/calm_snackbar.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import 'add_activity_sheet.dart';
import 'edit_activity_sheet.dart';

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Menjalankan aksi utama sebuah saran (§9).
void applySuggestionAction(
  BuildContext context,
  WidgetRef ref,
  Suggestion suggestion,
) {
  final state = ref.read(appStateProvider);
  final notifier = ref.read(appStateProvider.notifier);
  final navigator = Navigator.of(context);

  switch (suggestion.type) {
    case SuggestionType.independence:
      final activityId = suggestion.payload['activityId'] as String?;
      final activity = _firstWhereOrNull(
        state.activities,
        (a) => a.id == activityId,
      );
      if (activity == null) {
        navigator.pop();
        return;
      }
      notifier.updateState(
        state.copyWith(
          activities: [
            for (final a in state.activities)
              a.id == activity.id
                  ? a.copyWith(
                      independentMode: true,
                      steps: [activity.steps.first],
                    )
                  : a,
          ],
          suggestionStatus: {
            ...state.suggestionStatus,
            suggestion.id: SuggestionStatus.applied,
          },
        ),
      );
      navigator.pop();
      CalmSnackbar.show(
        context,
        message: 'Mode mandiri aktif untuk ${activity.title}',
      );
    case SuggestionType.emptyDay:
    case SuggestionType.quietTime:
      navigator.pop();
      _openAddSheet(context, ref, suggestion);
    case SuggestionType.transitionGap:
      navigator.pop();
      _openEditSheet(context, ref, suggestion);
  }
}

void _openAddSheet(
  BuildContext context,
  WidgetRef ref,
  Suggestion suggestion,
) {
  final state = ref.read(appStateProvider);
  final payload = suggestion.payload;

  if (suggestion.type == SuggestionType.quietTime) {
    final screenActivityId = payload['screenActivityId'] as String?;
    final screenActivity = _firstWhereOrNull(
      state.activities,
      (a) => a.id == screenActivityId,
    );
    if (screenActivity == null || screenActivity.end == null) return;
    final duration = payload['suggestedDuration'] as int? ?? 30;
    final start = screenActivity.end!;
    final endMin = start.toMinutes() + duration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddActivitySheet(
        childId: suggestion.childId,
        initialDate: screenActivity.date,
        initialTitle: 'Waktu tenang',
        initialIcon: ActivityIcon.tidur,
        initialStart: start,
        initialEnd: TimeOfDayLite(endMin ~/ 60, endMin % 60),
      ),
    );
    return;
  }

  final dateStr = payload['date'] as String?;
  if (dateStr == null) return;
  final date = DateTime.parse(dateStr);
  final icon = ActivityIcon.values.byName(payload['icon'] as String);
  final start = TimeOfDayLite.fromJson(
    Map<String, dynamic>.from(payload['start'] as Map),
  );
  final end = TimeOfDayLite.fromJson(
    Map<String, dynamic>.from(payload['end'] as Map),
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => AddActivitySheet(
      childId: suggestion.childId,
      initialDate: date,
      initialTitle: payload['title'] as String?,
      initialIcon: icon,
      initialStart: start,
      initialEnd: end,
    ),
  );
}

void _openEditSheet(
  BuildContext context,
  WidgetRef ref,
  Suggestion suggestion,
) {
  final state = ref.read(appStateProvider);
  final secondId = suggestion.payload['secondActivityId'] as String?;
  final requiredGap = suggestion.payload['requiredGap'] as int? ?? 10;
  final currentGap = suggestion.payload['currentGap'] as int? ?? 0;
  final second = _firstWhereOrNull(
    state.activities,
    (a) => a.id == secondId,
  );
  final child = _firstWhereOrNull(
    state.children,
    (c) => c.id == suggestion.childId,
  );
  if (second == null || child == null) return;

  final shift = requiredGap - currentGap;
  final shiftedStart = second.start.toMinutes() + shift;
  final shiftedEnd = second.end != null
      ? second.end!.toMinutes() + shift
      : null;

  final shifted = second.copyWith(
    start: TimeOfDayLite(shiftedStart ~/ 60, shiftedStart % 60),
    end: shiftedEnd != null
        ? TimeOfDayLite(shiftedEnd ~/ 60, shiftedEnd % 60)
        : null,
    clearEnd: shiftedEnd == null,
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => EditActivitySheet(activity: shifted, child: child),
  );
}
