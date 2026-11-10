import '../domain/reminder_plan.dart';

/// Menjadwalkan pengingat lokal di HP orang tua.
///
/// Implementasi sungguhan (flutter_local_notifications, mode
/// `AndroidScheduleMode.inexactAllowWhileIdle`) menunggu persetujuan paket;
/// sampai itu bawaannya [NoopReminderService].
abstract class ReminderService {
  /// Mengganti semua pengingat terjadwal dengan [plan].
  Future<void> reschedule(List<PlannedReminder> plan);

  /// Membatalkan semua pengingat (mis. saat keluar akun).
  Future<void> cancelAll();
}

class NoopReminderService implements ReminderService {
  const NoopReminderService();

  @override
  Future<void> reschedule(List<PlannedReminder> plan) async {}

  @override
  Future<void> cancelAll() async {}
}
