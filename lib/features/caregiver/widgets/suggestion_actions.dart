import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
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
///
/// Untuk quietTime, emptyDay, dan transitionGap, sheet form dibuka dengan
/// [Suggestion.id]; status saran menjadi `applied` hanya setelah jadwal
/// berhasil disimpan di sheet itu (§9.1).
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
                      originalSteps: activity.steps,
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
        navigator.context,
        message: 'Mode mandiri aktif untuk ${activity.title}',
      );
    case SuggestionType.emptyDay:
    case SuggestionType.quietTime:
      navigator.pop();
      _openAddSheet(navigator.context, state, suggestion);
    case SuggestionType.transitionGap:
      navigator.pop();
      _openEditSheet(navigator.context, state, suggestion);
  }
}

void _openAddSheet(
  BuildContext context,
  AppState state,
  Suggestion suggestion,
) {
  final payload = suggestion.payload;

  if (suggestion.type == SuggestionType.quietTime) {
    // Detail dari form Ubah membawa jam selesai kegiatan layar hasil ubahan
    // (belum tersimpan); tanpa itu, ambil dari kegiatan di state.
    final screenActivityId = payload['screenActivityId'] as String?;
    final screenActivity = _firstWhereOrNull(
      state.activities,
      (a) => a.id == screenActivityId,
    );
    final overrideEnd = payload['screenEnd'] == null
        ? null
        : TimeOfDayLite.fromJson(
            Map<String, dynamic>.from(payload['screenEnd'] as Map),
          );
    final start = overrideEnd ?? screenActivity?.end;
    if (start == null) return;
    final date = payload['screenDate'] != null
        ? DateTime.parse(payload['screenDate'] as String)
        : screenActivity!.date;
    final duration = payload['suggestedDuration'] as int? ?? 30;
    final endMin = start.toMinutes() + duration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparan,
      builder: (ctx) => AddActivitySheet(
        childId: suggestion.childId,
        initialDate: date,
        initialTitle: 'Waktu tenang',
        initialIcon: ActivityIcon.tidur,
        initialStart: start,
        initialEnd: TimeOfDayLite(endMin ~/ 60, endMin % 60),
        suggestionId: suggestion.id,
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
    backgroundColor: AppColors.transparan,
    builder: (ctx) => AddActivitySheet(
      childId: suggestion.childId,
      initialDate: date,
      initialTitle: payload['title'] as String?,
      initialIcon: icon,
      initialStart: start,
      initialEnd: end,
      suggestionId: suggestion.id,
    ),
  );
}

void _openEditSheet(
  BuildContext context,
  AppState state,
  Suggestion suggestion,
) {
  final secondId = suggestion.payload['secondActivityId'] as String?;
  final requiredGap = suggestion.payload['requiredGap'] as int? ?? 10;
  final currentGap = suggestion.payload['currentGap'] as int? ?? 0;
  final second = _firstWhereOrNull(state.activities, (a) => a.id == secondId);
  final child = _firstWhereOrNull(
    state.children,
    (c) => c.id == suggestion.childId,
  );
  if (second == null || child == null) return;

  // Jam usulan digeser, tetapi sheet menerima kegiatan ASLI dari state
  // sebagai dasar "sebelum". Dengan begitu pergeseran dihitung sebagai
  // perubahan inti: pesan wajib dan ChangeNotice dibuat (§8.7).
  final shift = requiredGap - currentGap;
  const lastMinute = 23 * 60 + 59;
  TimeOfDayLite shifted(TimeOfDayLite t) {
    final minutes = (t.toMinutes() + shift).clamp(0, lastMinute);
    return TimeOfDayLite(minutes ~/ 60, minutes % 60);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparan,
    builder: (ctx) => EditActivitySheet(
      activity: second,
      child: child,
      prefillStart: shifted(second.start),
      prefillEnd: second.end == null ? null : shifted(second.end!),
      suggestionId: suggestion.id,
    ),
  );
}
