import '../data/models/models.dart';

/// Status aktivitas untuk hari terpilih (HANDOFF §8.1)
enum ActivityStatus { biasa, selesai, sekarang, diubah }

/// Hasil perhitungan status aktivitas
class ActivityStatusResult {
  const ActivityStatusResult(this.status, {this.isNow = false});
  final ActivityStatus status;
  final bool isNow; // true jika ini aktivitas "Sekarang"
}

/// Menghitung status aktivitas untuk tanggal terpilih (§8.1)
ActivityStatusResult getActivityStatus({
  required Activity activity,
  required DateTime selectedDate,
  required DateTime now,
  required List<Completion> completions,
  required List<ChangeNotice> notices,
}) {
  // Cek completion untuk aktivitas ini di tanggal terpilih
  final hasCompletion = completions.any((c) =>
      c.activityId == activity.id &&
      c.date.year == selectedDate.year &&
      c.date.month == selectedDate.month &&
      c.date.day == selectedDate.day);

  if (hasCompletion) {
    return const ActivityStatusResult(ActivityStatus.selesai);
  }

  // Cek apakah ada notice untuk aktivitas ini hari ini
  final hasNoticeToday = notices.any((n) =>
      n.activityId == activity.id &&
      n.sentAt.year == selectedDate.year &&
      n.sentAt.month == selectedDate.month &&
      n.sentAt.day == selectedDate.day);

  // Cek "Sekarang" hanya jika tanggal = hari ini
  final isToday = selectedDate.year == now.year &&
      selectedDate.month == now.month &&
      selectedDate.day == now.day;

  if (isToday && !hasCompletion) {
    final startMinutes = activity.start.toMinutes();
    final nowMinutes = now.hour * 60 + now.minute;

    final endMinutes = activity.end?.toMinutes() ??
        (startMinutes + 30 * 60); // tanpa end: asumsi 30 jam (malam)

    // start <= now < end
    if (nowMinutes >= startMinutes && nowMinutes < endMinutes) {
      return const ActivityStatusResult(ActivityStatus.sekarang, isNow: true);
    }
  }

  // Diubah jika ada notice hari ini (untuk daftar orang tua)
  if (hasNoticeToday) {
    return const ActivityStatusResult(ActivityStatus.diubah);
  }

  return const ActivityStatusResult(ActivityStatus.biasa);
}

/// Menghitung progres anak di tanggal tertentu (§8.2)
/// Mengembalikan (selesai, total)
(int, int) calculateProgress({
  required String childId,
  required DateTime date,
  required List<Activity> activities,
  required List<Completion> completions,
}) {
  final childActivities = activities.where((a) =>
      a.childId == childId &&
      a.date.year == date.year &&
      a.date.month == date.month &&
      a.date.day == date.day);

  final total = childActivities.length;

  final selesai = childActivities.where((a) {
    return completions.any((c) =>
        c.activityId == a.id &&
        c.date.year == date.year &&
        c.date.month == date.month &&
        c.date.day == date.day);
  }).length;

  return (selesai, total);
}

/// Mengurutkan aktivitas berdasarkan jam mulai (§8.3)
List<Activity> sortActivitiesByStartTime(List<Activity> activities) {
  final sorted = List<Activity>.from(activities);
  sorted.sort((a, b) => a.start.toMinutes().compareTo(b.start.toMinutes()));
  return sorted;
}

/// Cek apakah dua aktivitas bentrok (§8.4)
bool hasConflict(Activity a, Activity b, {int assumedDurationMinutes = 30}) {
  if (a.childId != b.childId) return false;
  if (a.date.year != b.date.year ||
      a.date.month != b.date.month ||
      a.date.day != b.date.day) {
    return false;
  }
  if (a.id == b.id) return false;

  final aStart = a.start.toMinutes();
  final aEnd = a.end?.toMinutes() ?? (aStart + assumedDurationMinutes);

  final bStart = b.start.toMinutes();
  final bEnd = b.end?.toMinutes() ?? (bStart + assumedDurationMinutes);

  return aStart < bEnd && bStart < aEnd;
}

/// Mencari aktivitas yang bentrok dengan aktivitas tertentu (§8.4)
List<Activity> findConflicts({
  required Activity activity,
  required List<Activity> allActivities,
  int assumedDurationMinutes = 30,
}) {
  return allActivities
      .where((other) => hasConflict(activity, other,
          assumedDurationMinutes: assumedDurationMinutes))
      .toList();
}

/// Menghitung slot kosong terdekat setelah bentrok (§8.4)
TimeOfDayLite? findNearestFreeSlot({
  required Activity activity,
  required List<Activity> allActivities,
  required Activity conflictingActivity,
  int maxEndHour = 21,
}) {
  final duration = activity.end != null
      ? activity.end!.toMinutes() - activity.start.toMinutes()
      : 30;

  final conflictEnd = conflictingActivity.end?.toMinutes() ??
      (conflictingActivity.start.toMinutes() + 30);

  int candidateStart = conflictEnd + 10;

  while (candidateStart + duration <= maxEndHour * 60) {
    final candidateEnd = candidateStart + duration;
    final candidate = activity.copyWith(
      start: TimeOfDayLite(candidateStart ~/ 60, candidateStart % 60),
      end: TimeOfDayLite(candidateEnd ~/ 60, candidateEnd % 60),
    );

    final conflicts = findConflicts(
      activity: candidate,
      allActivities: allActivities,
    );

    if (conflicts.isEmpty) {
      return candidate.start;
    }

    candidateStart = conflicts.first.end?.toMinutes() ??
        (conflicts.first.start.toMinutes() + 30);
    candidateStart += 10;
  }

  return null;
}

/// Menghitung jeda antara dua aktivitas berurutan (§8.5)
int? calculateGapMinutes(Activity first, Activity second) {
  if (first.childId != second.childId) return null;
  if (first.date.year != second.date.year ||
      first.date.month != second.date.month ||
      first.date.day != second.date.day) {
    return null;
  }

  final firstEnd = first.end?.toMinutes();
  if (firstEnd == null) return null;

  final secondStart = second.start.toMinutes();
  return secondStart - firstEnd;
}

/// Mencari aktivitas "Sekarang" untuk anak di hari ini (§8.1)
Activity? findCurrentActivity({
  required String childId,
  required DateTime now,
  required List<Activity> activities,
  required List<Completion> completions,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final todayActivities = activities
      .where((a) =>
          a.childId == childId &&
          a.date.year == today.year &&
          a.date.month == today.month &&
          a.date.day == today.day)
      .toList();

  Activity? current;
  int latestStart = -1;

  for (final activity in todayActivities) {
    final status = getActivityStatus(
      activity: activity,
      selectedDate: today,
      now: now,
      completions: completions,
      notices: const [],
    );

    if (status.isNow && activity.start.toMinutes() > latestStart) {
      current = activity;
      latestStart = activity.start.toMinutes();
    }
  }

  return current;
}

/// Menghitung berapa kali aktivitas muncul berturut-turut selesai tepat waktu (§9.3)
int countConsecutiveOnTimeCompletions({
  required Activity activity,
  required DateTime referenceDate,
  required List<Activity> allActivities,
  required List<Completion> completions,
}) {
  if (activity.repeatWeekdays.isEmpty) {
    return 0;
  }

  final refDateOnly = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

  // Cari aktivitas terkait sebelum hari referenceDate (tidak termasuk hari ini)
  final relatedActivities = allActivities.where((a) {
    final actDateOnly = DateTime(a.date.year, a.date.month, a.date.day);
    final match = a.childId == activity.childId &&
        a.icon == activity.icon &&
        a.title == activity.title &&
        a.start == activity.start &&
        a.end == activity.end &&
        a.repeatWeekdays.isNotEmpty &&
        actDateOnly.isBefore(refDateOnly);
    return match;
  }).toList();

  // Sort terbaru ke terlama
  relatedActivities.sort((a, b) => b.date.compareTo(a.date));

  int count = 0;
  for (final act in relatedActivities) {
    final comp = completions.where((c) =>
        c.activityId == act.id &&
        c.date.year == act.date.year &&
        c.date.month == act.date.month &&
        c.date.day == act.date.day);

    if (comp.isEmpty) break;
    if (!comp.first.onTime) break;

    count++;
  }

  return count;
}

