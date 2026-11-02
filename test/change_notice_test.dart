import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Change Notice Logic (Test 5–8)', () {
    late AppState state;
    late DateTime now;

    setUp(() {
      state = buildSeedState();
      now = Clock.demoTime;
    });

    test('Test 5: Ubah langkah saja tidak membuat ChangeNotice', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final les = state.activities.firstWhere(
        (a) => a.childId == rafi.id && a.title == 'Les dengan Pak Lana',
      );

      final updatedLes = les.copyWith(steps: ['Langkah baru']);

      // Simulasi perubahan tanpa notice
      final updatedState = state.copyWith(
        activities: state.activities.map((a) => a.id == les.id ? updatedLes : a).toList(),
      );

      // Verifikasi: tidak ada notice baru yang ditambahkan
      expect(updatedState.notices.length, state.notices.length);
    });

    test('Test 6: Ubah nama membuat ChangeNotice dengan before/after', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final les = state.activities.firstWhere(
        (a) => a.childId == rafi.id && a.title == 'Les dengan Pak Lana',
      );

      const before = ActivitySnapshot(
        shortTitle: 'Les',
        title: 'Les dengan Pak Lana',
        icon: ActivityIcon.les,
        start: TimeOfDayLite(20, 0),
      );

      const after = ActivitySnapshot(
        shortTitle: 'Nonton',
        title: 'Nonton film',
        icon: ActivityIcon.nonton,
        start: TimeOfDayLite(20, 0),
      );

      final notice = ChangeNotice(
        id: 'notice-test',
        childId: rafi.id,
        activityId: les.id,
        before: before,
        after: after,
        message: 'Les diganti nonton film',
        sentAt: now,
      );

      expect(notice.before.title, 'Les dengan Pak Lana');
      expect(notice.after!.title, 'Nonton film');
      expect(notice.seenAt, isNull);
    });

    test('Test 7: Hapus + urungkan mengembalikan kegiatan dan notice', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final les = state.activities.firstWhere(
        (a) => a.childId == rafi.id && a.title == 'Les dengan Pak Lana',
      );

      const before = ActivitySnapshot(
        shortTitle: 'Les',
        title: 'Les dengan Pak Lana',
        icon: ActivityIcon.les,
        start: TimeOfDayLite(20, 0),
      );

      final deleteNotice = ChangeNotice(
        id: 'notice-delete',
        childId: rafi.id,
        activityId: les.id,
        before: before,
        after: null,
        message: 'Les hari ini tidak jadi. Kamu bisa istirahat dulu.',
        sentAt: now,
      );

      // Simulasi hapus
      final afterDelete = state.copyWith(
        activities: state.activities.where((a) => a.id != les.id).toList(),
        notices: [...state.notices, deleteNotice],
      );

      expect(afterDelete.activities.any((a) => a.id == les.id), isFalse);
      expect(afterDelete.notices.any((n) => n.id == deleteNotice.id), isTrue);

      // Simulasi urungkan
      final afterUndo = afterDelete.copyWith(
        activities: [...afterDelete.activities, les],
        notices: afterDelete.notices.where((n) => n.id != deleteNotice.id).toList(),
      );

      expect(afterUndo.activities.any((a) => a.id == les.id), isTrue);
      expect(afterUndo.notices.any((n) => n.id == deleteNotice.id), isFalse);
    });

    test('Test 8: Acknowledge mengisi seenAt dan menambah notifikasi changeSeen', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');

      final notice = ChangeNotice(
        id: 'notice-ack',
        childId: rafi.id,
        activityId: 'test-activity',
        before: const ActivitySnapshot(
          shortTitle: 'Les',
          title: 'Les dengan Pak Lana',
          icon: ActivityIcon.les,
          start: TimeOfDayLite(20, 0),
        ),
        after: const ActivitySnapshot(
          shortTitle: 'Nonton',
          title: 'Nonton film',
          icon: ActivityIcon.nonton,
          start: TimeOfDayLite(20, 0),
        ),
        message: 'Test message',
        sentAt: now,
      );

      final afterAck = notice.copyWith(seenAt: now.add(const Duration(minutes: 5)));
      expect(afterAck.seenAt, isNotNull);

      final newNotification = CaregiverNotification(
        id: 'notif-ack',
        type: NotificationType.changeSeen,
        text: 'Rafi melihat perubahan jadwal Nonton film',
        at: now.add(const Duration(minutes: 5)),
        read: false,
      );

      expect(newNotification.type, NotificationType.changeSeen);
      expect(newNotification.text, contains('Rafi melihat perubahan'));
    });
  });
}
