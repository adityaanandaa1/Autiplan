import '../data/models/models.dart';

/// Satu pengingat lokal yang akan dijadwalkan di HP orang tua.
class PlannedReminder {
  const PlannedReminder({
    required this.activityId,
    required this.at,
    required this.body,
  });

  final String activityId;
  final DateTime at;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.activityId == activityId &&
      other.at == at &&
      other.body == body;

  @override
  int get hashCode => Object.hash(activityId, at, body);
}

/// Daftar pengingat yang masih akan datang, paling awal dulu, maksimal
/// [maxCount]. Waktu yang sudah lewat dan kegiatan selesai dilewati.
List<PlannedReminder> planReminders(
  AppState state,
  DateTime now, {
  int maxCount = 50,
}) {
  final minutes = state.settings.reminderMinutesBefore;
  final doneIds = {for (final c in state.completions) c.activityId};
  final childNames = {for (final c in state.children) c.id: c.name};
  final result = <PlannedReminder>[];
  for (final a in state.activities) {
    final childName = childNames[a.childId];
    if (childName == null || doneIds.contains(a.id)) continue;
    final start = DateTime(
      a.date.year,
      a.date.month,
      a.date.day,
      a.start.hour,
      a.start.minute,
    );
    final at = start.subtract(Duration(minutes: minutes));
    if (!at.isAfter(now)) continue;
    result.add(
      PlannedReminder(
        activityId: a.id,
        at: at,
        body: '${a.title} untuk $childName mulai $minutes menit lagi.',
      ),
    );
  }
  result.sort((x, y) => x.at.compareTo(y.at));
  return result.length > maxCount ? result.sublist(0, maxCount) : result;
}
