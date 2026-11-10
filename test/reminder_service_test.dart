import 'package:autiplan/data/reminder_service.dart';
import 'package:autiplan/domain/reminder_plan.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGateway implements NotificationGateway {
  _FakeGateway({this.permitted = true});

  final bool permitted;
  final calls = <String>[];
  int initCount = 0;

  @override
  Future<void> initialize() async {
    initCount++;
    calls.add('init');
  }

  @override
  Future<bool> requestPermission() async {
    calls.add('izin');
    return permitted;
  }

  @override
  Future<void> cancelAll() async => calls.add('cancelAll');

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async => calls.add('jadwal:$id:$body');
}

void main() {
  final at1 = DateTime(2026, 11, 11, 7, 45);
  final at2 = DateTime(2026, 11, 11, 15, 45);
  final plan = [
    PlannedReminder(activityId: 'a1', at: at1, body: 'Sekolah untuk Rafi'),
    PlannedReminder(activityId: 'a2', at: at2, body: 'Les untuk Rafi'),
  ];

  test('id stabil dan berbeda untuk kegiatan atau waktu berbeda', () {
    expect(
      reminderNotificationId('a1', at1),
      reminderNotificationId('a1', at1),
    );
    expect(
      reminderNotificationId('a1', at1),
      isNot(reminderNotificationId('a2', at1)),
    );
    expect(
      reminderNotificationId('a1', at1),
      isNot(reminderNotificationId('a1', at2)),
    );
    expect(reminderNotificationId('a1', at1), greaterThanOrEqualTo(0));
  });

  test(
    'reschedule membatalkan dulu lalu menjadwalkan tiap pengingat',
    () async {
      final gateway = _FakeGateway();
      final service = FlutterLocalNotificationsReminderService(
        gateway: gateway,
      );
      await service.reschedule(plan);
      expect(gateway.calls, [
        'init',
        'izin',
        'cancelAll',
        'jadwal:${reminderNotificationId('a1', at1)}:Sekolah untuk Rafi',
        'jadwal:${reminderNotificationId('a2', at2)}:Les untuk Rafi',
      ]);
    },
  );

  test('inisialisasi dan izin hanya sekali', () async {
    final gateway = _FakeGateway();
    final service = FlutterLocalNotificationsReminderService(gateway: gateway);
    await service.reschedule(plan);
    await service.reschedule(const []);
    await service.cancelAll();
    expect(gateway.initCount, 1);
    expect(gateway.calls.where((c) => c == 'izin'), hasLength(1));
  });

  test('tanpa izin tidak menjadwalkan apa pun', () async {
    final gateway = _FakeGateway(permitted: false);
    final service = FlutterLocalNotificationsReminderService(gateway: gateway);
    await service.reschedule(plan);
    expect(gateway.calls.any((c) => c.startsWith('jadwal')), isFalse);
    expect(gateway.calls, contains('cancelAll'));
  });
}
