import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../data/models/models.dart';
import '../../../domain/schedule_rules.dart';
import 'form_field.dart';
import 'form_utils.dart';

/// Umpan balik di bawah kolom Waktu pada form Tambah dan Ubah:
/// rentang waktu tidak valid (§8.6), bentrok + tautan slot kosong (§8.4),
/// dan teks bantu jeda transisi (§8.5).
class TimeFeedback extends StatelessWidget {
  const TimeFeedback({
    super.key,
    required this.candidate,
    required this.allActivities,
    required this.minGapMinutes,
    required this.childName,
    required this.onUseSlot,
  });

  /// Kegiatan hasil isian saat ini.
  final Activity candidate;
  final List<Activity> allActivities;
  final int minGapMinutes;
  final String childName;

  /// Dipanggil saat "Pakai {slot}" ditekan.
  final void Function(TimeOfDayLite start, TimeOfDayLite? end) onUseSlot;

  /// Waktu yang menghalangi simpan: rentang tidak valid atau bentrok.
  static bool blocksSave(Activity candidate, List<Activity> allActivities) =>
      _issue(candidate) != null ||
      findConflicts(
        activity: candidate,
        allActivities: allActivities,
      ).isNotEmpty;

  static TimeRangeIssue? _issue(Activity a) =>
      validateTimeRange(icon: a.icon, start: a.start, end: a.end);

  @override
  Widget build(BuildContext context) {
    final issue = _issue(candidate);
    final conflicts = findConflicts(
      activity: candidate,
      allActivities: allActivities,
    );

    final children = <Widget>[];

    if (issue != null) {
      children
        ..add(const SizedBox(height: AppSpacing.grid12))
        ..add(FormInfoBox(text: timeRangeIssueMessage(issue)));
    }

    if (conflicts.isNotEmpty) {
      final first = conflicts.first;
      TimeOfDayLite? slot;
      TimeOfDayLite? slotEnd;
      if (issue == null) {
        slot = findNearestFreeSlot(
          activity: candidate,
          allActivities: allActivities,
          conflictingActivity: first,
          minGapMinutes: minGapMinutes,
        );
        if (slot != null && candidate.end != null) {
          final duration =
              candidate.end!.toMinutes() - candidate.start.toMinutes();
          final endMinutes = slot.toMinutes() + duration;
          slotEnd = TimeOfDayLite(endMinutes ~/ 60, endMinutes % 60);
        }
      }
      final firstEnd = first.end != null ? formatTimeLite(first.end!) : 'Pagi';
      children
        ..add(const SizedBox(height: AppSpacing.grid12))
        ..add(
          FormInfoBox(
            text:
                'Waktu ini bentrok dengan ${first.title} '
                '(${formatTimeLite(first.start)}–$firstEnd). '
                'Pilih waktu lain supaya $childName tidak bingung.',
            actionLabel: slot == null
                ? null
                : slotEnd == null
                ? 'Pakai ${formatTimeLite(slot)}'
                : 'Pakai ${formatTimeLite(slot)} – ${formatTimeLite(slotEnd)}',
            onAction: slot == null ? null : () => onUseSlot(slot!, slotEnd),
          ),
        );
    } else if (issue == null) {
      final gap = findShortGapBefore(
        activity: candidate,
        allActivities: allActivities,
        minGapMinutes: minGapMinutes,
      );
      if (gap != null) {
        children
          ..add(const SizedBox(height: AppSpacing.grid8))
          ..add(
            Text(
              'Jeda dengan ${gap.previous.title} hanya ${gap.gap} menit.',
              style: AppTypography.meta,
            ),
          );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
