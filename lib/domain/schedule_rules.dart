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
  final hasCompletion = completions.any(
    (c) =>
        c.activityId == activity.id &&
        c.date.year == selectedDate.year &&
        c.date.month == selectedDate.month &&
        c.date.day == selectedDate.day,
  );

  if (hasCompletion) {
    return const ActivityStatusResult(ActivityStatus.selesai);
  }

  // Cek apakah ada notice untuk aktivitas ini hari ini
  final hasNoticeToday = notices.any(
    (n) =>
        n.activityId == activity.id &&
        n.sentAt.year == selectedDate.year &&
        n.sentAt.month == selectedDate.month &&
        n.sentAt.day == selectedDate.day,
  );

  // Cek "Sekarang" hanya jika tanggal = hari ini
  final isToday =
      selectedDate.year == now.year &&
      selectedDate.month == now.month &&
      selectedDate.day == now.day;

  if (isToday && !hasCompletion) {
    final startMinutes = activity.start.toMinutes();
    final nowMinutes = now.hour * 60 + now.minute;

    final endMinutes = activity.end?.toMinutes();

    // start <= now < end; tanpa end: start <= now (§8.1)
    if (nowMinutes >= startMinutes &&
        (endMinutes == null || nowMinutes < endMinutes)) {
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
  final childActivities = activities.where(
    (a) =>
        a.childId == childId &&
        a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day,
  );

  final total = childActivities.length;

  final selesai = childActivities.where((a) {
    return completions.any(
      (c) =>
          c.activityId == a.id &&
          c.date.year == date.year &&
          c.date.month == date.month &&
          c.date.day == date.day,
    );
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
      .where(
        (other) => hasConflict(
          activity,
          other,
          assumedDurationMinutes: assumedDurationMinutes,
        ),
      )
      .toList();
}

/// Menghitung slot kosong terdekat setelah bentrok (§8.4)
TimeOfDayLite? findNearestFreeSlot({
  required Activity activity,
  required List<Activity> allActivities,
  required Activity conflictingActivity,
  int maxEndHour = 21,
  int minGapMinutes = 10,
}) {
  final duration = activity.end != null
      ? activity.end!.toMinutes() - activity.start.toMinutes()
      : 30;

  final conflictEnd =
      conflictingActivity.end?.toMinutes() ??
      (conflictingActivity.start.toMinutes() + 30);

  int candidateStart = conflictEnd + minGapMinutes;

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

    candidateStart =
        conflicts.first.end?.toMinutes() ??
        (conflicts.first.start.toMinutes() + 30);
    candidateStart += minGapMinutes;
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
      .where(
        (a) =>
            a.childId == childId &&
            a.date.year == today.year &&
            a.date.month == today.month &&
            a.date.day == today.day,
      )
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
  return consecutiveOnTimeDates(
    activity: activity,
    referenceDate: referenceDate,
    allActivities: allActivities,
    completions: completions,
  ).length;
}

/// Tanggal kemunculan yang selesai tepat waktu berturut-turut (§9.3),
/// diurutkan dari terbaru ke terlama. Kemunculan hari referensi dilewati.
List<DateTime> consecutiveOnTimeDates({
  required Activity activity,
  required DateTime referenceDate,
  required List<Activity> allActivities,
  required List<Completion> completions,
}) {
  if (activity.repeatWeekdays.isEmpty) {
    return const [];
  }

  final refDateOnly = DateTime(
    referenceDate.year,
    referenceDate.month,
    referenceDate.day,
  );

  final relatedActivities = allActivities.where((a) {
    final actDateOnly = DateTime(a.date.year, a.date.month, a.date.day);
    return a.childId == activity.childId &&
        a.icon == activity.icon &&
        a.title == activity.title &&
        a.start == activity.start &&
        a.end == activity.end &&
        a.repeatWeekdays.isNotEmpty &&
        actDateOnly.isBefore(refDateOnly);
  }).toList();

  // Sort terbaru ke terlama
  relatedActivities.sort((a, b) => b.date.compareTo(a.date));

  final dates = <DateTime>[];
  for (final act in relatedActivities) {
    final comp = completions.where(
      (c) =>
          c.activityId == act.id &&
          c.date.year == act.date.year &&
          c.date.month == act.date.month &&
          c.date.day == act.date.day,
    );

    if (comp.isEmpty) break;
    if (!comp.first.onTime) break;

    dates.add(DateTime(act.date.year, act.date.month, act.date.day));
  }

  return dates;
}

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Rentang tanggal: "24–30 April" (satu bulan) atau "28 April–2 Mei" (§9.3).
/// Satu tanggal saja ditulis "24 April".
String formatDateRange(DateTime from, DateTime to) {
  final a = from.isAfter(to) ? to : from;
  final b = from.isAfter(to) ? from : to;
  final aMonth = _monthNames[a.month - 1];
  final bMonth = _monthNames[b.month - 1];
  if (a.year == b.year && a.month == b.month) {
    if (a.day == b.day) return '${a.day} $aMonth';
    return '${a.day}–${b.day} $aMonth';
  }
  return '${a.day} $aMonth–${b.day} $bMonth';
}

/// Hasil ubah kegiatan (§8.7). [notice] null bila tidak ada perubahan inti.
class ActivityEditResult {
  const ActivityEditResult(this.state, this.notice);
  final AppState state;
  final ChangeNotice? notice;
}

ActivitySnapshot _snapshotOf(Activity a) => ActivitySnapshot(
  shortTitle: a.shortTitle,
  title: a.title,
  icon: a.icon,
  start: a.start,
);

/// Mengubah kegiatan (§8.7). Perubahan nama/ikon/jam (start, end) membuat
/// [ChangeNotice] dan wajib [message] 1–120 karakter (ArgumentError bila
/// tidak). Perubahan lain (langkah/ulangi/mode mandiri/layar) hanya
/// memperbarui kegiatan. ID notice dibuat pemanggil.
ActivityEditResult applyActivityEdit({
  required AppState state,
  required Activity updated,
  required String? message,
  required DateTime now,
  required String noticeId,
}) {
  final old = state.activities.firstWhere(
    (a) => a.id == updated.id,
    orElse: () =>
        throw ArgumentError.value(updated.id, 'updated', 'kegiatan tidak ada'),
  );

  final coreChanged =
      old.title != updated.title ||
      old.icon != updated.icon ||
      old.start != updated.start ||
      old.end != updated.end;

  if (!coreChanged) {
    return ActivityEditResult(
      state.copyWith(
        activities: [
          for (final a in state.activities) a.id == updated.id ? updated : a,
        ],
      ),
      null,
    );
  }

  final text = message?.trim() ?? '';
  if (text.isEmpty || text.length > 120) {
    throw ArgumentError.value(message, 'message', 'pesan wajib 1–120 karakter');
  }

  final stored = updated.copyWith(replacedTitle: old.title);
  final notice = ChangeNotice(
    id: noticeId,
    childId: old.childId,
    activityId: old.id,
    before: _snapshotOf(old),
    after: _snapshotOf(stored),
    message: text,
    sentAt: now,
  );
  return ActivityEditResult(
    state.copyWith(
      activities: [
        for (final a in state.activities) a.id == stored.id ? stored : a,
      ],
      notices: [...state.notices, notice],
    ),
    notice,
  );
}

/// Hasil hapus kegiatan (§8.8), cukup untuk [undoDeleteActivity].
class ActivityDeleteResult {
  const ActivityDeleteResult({
    required this.state,
    required this.activity,
    required this.index,
    required this.noticeId,
  });
  final AppState state; // state setelah hapus
  final Activity activity; // kegiatan yang dihapus
  final int index; // posisi asli dalam daftar kegiatan
  final String noticeId;
}

/// Menghapus kegiatan dan membuat ChangeNotice (after = null) dengan pesan
/// otomatis (§8.8).
ActivityDeleteResult deleteActivity({
  required AppState state,
  required String activityId,
  required DateTime now,
  required String noticeId,
}) {
  final index = state.activities.indexWhere((a) => a.id == activityId);
  if (index == -1) {
    throw ArgumentError.value(activityId, 'activityId', 'kegiatan tidak ada');
  }
  final activity = state.activities[index];
  final notice = ChangeNotice(
    id: noticeId,
    childId: activity.childId,
    activityId: activity.id,
    before: _snapshotOf(activity),
    message:
        '${activity.title} hari ini tidak jadi. '
        'Kamu bisa istirahat dulu.',
    sentAt: now,
  );
  return ActivityDeleteResult(
    state: state.copyWith(
      activities: [...state.activities]..removeAt(index),
      notices: [...state.notices, notice],
    ),
    activity: activity,
    index: index,
    noticeId: noticeId,
  );
}

/// Urungkan hapus: kegiatan kembali ke posisi semula, notice dihapus (§8.8).
AppState undoDeleteActivity(AppState current, ActivityDeleteResult deleted) {
  final activities = [...current.activities];
  activities.insert(
    deleted.index.clamp(0, activities.length),
    deleted.activity,
  );
  return current.copyWith(
    activities: activities,
    notices: current.notices.where((n) => n.id != deleted.noticeId).toList(),
  );
}

/// Anak menekan "Oke, aku mengerti" (§8.9): seenAt = now dan tambah
/// notifikasi changeSeen. Notice yang sudah dilihat tidak diubah lagi.
AppState acknowledgeNotice({
  required AppState state,
  required String noticeId,
  required DateTime now,
  required String notificationId,
}) {
  final notice = state.notices.firstWhere(
    (n) => n.id == noticeId,
    orElse: () =>
        throw ArgumentError.value(noticeId, 'noticeId', 'notice tidak ada'),
  );
  if (notice.seenAt != null) return state;

  final child = state.children.firstWhere((c) => c.id == notice.childId);
  final title = (notice.after ?? notice.before).title;
  return state.copyWith(
    notices: [
      for (final n in state.notices)
        n.id == noticeId ? n.copyWith(seenAt: now) : n,
    ],
    notifications: [
      ...state.notifications,
      CaregiverNotification(
        id: notificationId,
        type: NotificationType.changeSeen,
        text: '${child.name} melihat perubahan jadwal $title',
        at: now,
        read: false,
      ),
    ],
  );
}

/// Tombol "Aku sudah selesai" aktif? (§8.10)
bool canComplete(Activity activity, int checkedStepCount) =>
    activity.steps.isEmpty ||
    activity.independentMode ||
    checkedStepCount >= activity.steps.length;
