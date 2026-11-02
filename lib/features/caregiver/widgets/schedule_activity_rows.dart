import 'package:flutter/material.dart';

import '../../../core/widgets/activity_row.dart';
import '../../../data/models/models.dart';
import '../../../domain/schedule_rules.dart';
import 'edit_activity_sheet.dart';

List<Widget> buildScheduleActivityRows({
  required BuildContext context,
  required List<Activity> activities,
  required DateTime selectedDate,
  required DateTime now,
  required AppState state,
  required Child child,
}) {
  // Maksimal satu "Sekarang" per anak: start paling akhir (§8.1).
  final currentId = findCurrentActivity(
    childId: child.id,
    now: now,
    activities: state.activities,
    completions: state.completions,
  )?.id;

  return activities.map((activity) {
    final statusResult = getActivityStatus(
      activity: activity,
      selectedDate: selectedDate,
      now: now,
      completions: state.completions,
      notices: state.notices,
    );

    ActivityRowStatus rowStatus = ActivityRowStatus.normal;
    if (statusResult.status == ActivityStatus.selesai) {
      rowStatus = ActivityRowStatus.completed;
    } else if (statusResult.status == ActivityStatus.sekarang &&
        activity.id == currentId) {
      rowStatus = ActivityRowStatus.now;
    } else if (statusResult.status == ActivityStatus.sekarang) {
      // Berlangsung juga, tapi bukan yang dipilih: tampil biasa/diubah.
      final hasNotice = state.notices.any(
        (n) =>
            n.activityId == activity.id &&
            n.sentAt.year == selectedDate.year &&
            n.sentAt.month == selectedDate.month &&
            n.sentAt.day == selectedDate.day,
      );
      if (hasNotice) rowStatus = ActivityRowStatus.changed;
    } else if (statusResult.status == ActivityStatus.diubah) {
      rowStatus = ActivityRowStatus.changed;
    }

    final end = activity.end;
    final timeRange = end != null
        ? '${activity.start} – $end'
        : activity.icon == ActivityIcon.tidur
        ? '${activity.start} – Pagi'
        : activity.start.toString();

    return ActivityRow(
      key: ValueKey(activity.id),
      startTime: activity.start.toString(),
      icon: activity.icon,
      title: activity.title,
      subtitle: rowStatus == ActivityRowStatus.now ? timeRange : null,
      replacedTitle: activity.replacedTitle,
      status: rowStatus,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => EditActivitySheet(activity: activity, child: child),
        );
      },
    );
  }).toList();
}
