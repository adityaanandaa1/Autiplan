import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder_plan.dart';

/// Menjadwalkan pengingat lokal di HP orang tua.
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

/// Lapisan tipis di atas plugin notifikasi supaya layanan bisa dites dengan
/// pengganti palsu tanpa plugin asli.
abstract class NotificationGateway {
  /// Menyiapkan plugin dan zona waktu lokal. Aman dipanggil berulang.
  Future<void> initialize();

  /// Meminta izin notifikasi (Android 13+). Mengembalikan true bila diberikan.
  Future<bool> requestPermission();

  Future<void> cancelAll();

  /// Menjadwalkan satu notifikasi pada waktu dinding lokal [at].
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  });
}

/// ID notifikasi yang stabil dari [activityId] dan [at] (FNV-1a 32-bit,
/// dipangkas ke 31 bit supaya selalu positif).
int reminderNotificationId(String activityId, DateTime at) {
  var hash = 0x811c9dc5;
  for (final unit in '$activityId|${at.millisecondsSinceEpoch}'.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

class FlutterLocalNotificationsReminderService implements ReminderService {
  FlutterLocalNotificationsReminderService({NotificationGateway? gateway})
    : _gateway = gateway ?? PluginNotificationGateway();

  static const title = 'AutiPlan';

  final NotificationGateway _gateway;
  bool _ready = false;
  bool _permitted = false;

  Future<void> _prepare() async {
    if (_ready) return;
    await _gateway.initialize();
    _permitted = await _gateway.requestPermission();
    _ready = true;
  }

  @override
  Future<void> reschedule(List<PlannedReminder> plan) async {
    await _prepare();
    await _gateway.cancelAll();
    if (!_permitted) return;
    for (final reminder in plan) {
      await _gateway.schedule(
        id: reminderNotificationId(reminder.activityId, reminder.at),
        title: title,
        body: reminder.body,
        at: reminder.at,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _prepare();
    await _gateway.cancelAll();
  }
}

/// Gateway nyata: flutter_local_notifications + timezone + flutter_timezone.
/// Tidak dites otomatis karena butuh plugin platform.
class PluginNotificationGateway implements NotificationGateway {
  PluginNotificationGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // Tanpa suara dan getar (HANDOFF §14). Channel Android menyimpan setelan
  // ini sejak dibuat, jadi id channel diganti bila setelannya berubah.
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'pengingat_kegiatan',
      'Pengingat kegiatan',
      channelDescription: 'Pengingat sebelum kegiatan anak dimulai.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      enableVibration: false,
    ),
  );

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Zona waktu lokal tidak terbaca, memakai UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAllPendingNotifications();

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) {
    // `at` adalah waktu dinding lokal; tz.local sudah diatur ke zona perangkat.
    final when = tz.TZDateTime(
      tz.local,
      at.year,
      at.month,
      at.day,
      at.hour,
      at.minute,
      at.second,
    );
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
