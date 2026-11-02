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
    } else if (statusResult.status == ActivityStatus.sekarang) {
      rowStatus = ActivityRowStatus.now;
    } else if (statusResult.status == ActivityStatus.diubah) {
      rowStatus = ActivityRowStatus.changed;
    }

    final endText = activity.end != null ? activity.end!.toString() : 'Pagi';

    return ActivityRow(
      key: ValueKey(activity.id),
      startTime: activity.start.toString(),
      icon: activity.icon,
      title: activity.title,
      subtitle: rowStatus == ActivityRowStatus.now
          ? '${activity.start.toString()} – $endText'
          : null,
      replacedTitle: activity.replacedTitle,
      status: rowStatus,
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => EditActivitySheet(
            activity: activity,
            child: child,
          ),
        );
      },
    );
  }).toList();
}
