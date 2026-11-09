import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Change Notice Logic (Test 5–8)', () {
    late AppState state;
    late DateTime now;
    late Activity les;

    setUp(() {
      state = buildFixtureState();
      now = fixtureNow;
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      les = state.activities.firstWhere(
        (a) => a.childId == rafi.id && a.title == 'Les dengan Pak Lana',
      );
    });

    test('Test 5: Ubah langkah saja tidak membuat ChangeNotice', () {
      final updated = les.copyWith(
        steps: ['Langkah baru'],
        independentMode: true,
      );
      final result = applyActivityEdit(
        state: state,
        updated: updated,
        message: null,
        now: now,
        noticeId: 'n-1',
      );

      expect(result.notice, isNull);
      expect(result.state.notices.length, state.notices.length);
      final stored = result.state.activities.firstWhere((a) => a.id == les.id);
      expect(stored.steps, ['Langkah baru']);
      expect(stored.independentMode, isTrue);
      expect(stored.replacedTitle, les.replacedTitle);
    });

    test('Test 6: Ubah nama membuat ChangeNotice dengan before/after', () {
      final updated = les.copyWith(
        title: 'Nonton film',
        shortTitle: 'Nonton',
        icon: ActivityIcon.nonton,
      );
      final result = applyActivityEdit(
        state: state,
        updated: updated,
        message: 'Hari ini nonton film dulu ya',
        now: now,
        noticeId: 'n-1',
      );

      final notice = result.notice!;
      expect(result.state.notices, [...state.notices, notice]);
      expect(notice.id, 'n-1');
      expect(notice.childId, les.childId);
      expect(notice.activityId, les.id);
      expect(notice.before.shortTitle, 'Les');
      expect(notice.before.title, 'Les dengan Pak Lana');
      expect(notice.after!.title, 'Nonton film');
      expect(notice.after!.shortTitle, 'Nonton');
      expect(notice.message, 'Hari ini nonton film dulu ya');
      expect(notice.sentAt, now);
      expect(notice.seenAt, isNull);

      final stored = result.state.activities.firstWhere((a) => a.id == les.id);
      expect(stored.title, 'Nonton film');
      expect(stored.replacedTitle, 'Les dengan Pak Lana');
    });

    test('Test 6: perubahan jam saja juga membuat notice', () {
      final updated = les.copyWith(start: const TimeOfDayLite(19, 30));
      final result = applyActivityEdit(
        state: state,
        updated: updated,
        message: 'Lesnya maju setengah jam',
        now: now,
        noticeId: 'n-1',
      );
      expect(result.notice, isNotNull);
      expect(result.notice!.after!.start, const TimeOfDayLite(19, 30));
    });

    test('Test 6: pesan wajib 1–120 karakter bila perubahan inti', () {
      final updated = les.copyWith(title: 'Nonton film');
      for (final bad in [null, '', '   ', 'a' * 121]) {
        expect(
          () => applyActivityEdit(
            state: state,
            updated: updated,
            message: bad,
            now: now,
            noticeId: 'n-1',
          ),
          throwsArgumentError,
          reason: 'pesan: $bad',
        );
      }
      final ok = applyActivityEdit(
        state: state,
        updated: updated,
        message: 'a' * 120,
        now: now,
        noticeId: 'n-1',
      );
      expect(ok.notice, isNotNull);
    });

    test('Test 7: Hapus + urungkan mengembalikan kegiatan dan notice', () {
      final deleted = deleteActivity(
        state: state,
        activityId: les.id,
        now: now,
        noticeId: 'n-del',
      );

      expect(deleted.state.activities.any((a) => a.id == les.id), isFalse);
      final notice = deleted.state.notices.singleWhere((n) => n.id == 'n-del');
      expect(notice.after, isNull);
      expect(notice.before.title, 'Les dengan Pak Lana');
      expect(
        notice.message,
        'Les dengan Pak Lana hari ini tidak jadi. Kamu bisa istirahat dulu.',
      );
      expect(notice.sentAt, now);
      expect(deleted.activity, les);

      final restored = undoDeleteActivity(deleted.state, deleted);
      expect(restored, state);
    });

    test('Test 8: Acknowledge mengisi seenAt dan menambah notifikasi', () {
      final edited = applyActivityEdit(
        state: state,
        updated: les.copyWith(title: 'Nonton film', shortTitle: 'Nonton'),
        message: 'Nonton dulu ya',
        now: now,
        noticeId: 'n-1',
      );
      final seenAt = now.add(const Duration(minutes: 5));
      final acked = acknowledgeNotice(
        state: edited.state,
        noticeId: 'n-1',
        now: seenAt,
        notificationId: 'notif-ack',
      );

      final notice = acked.notices.singleWhere((n) => n.id == 'n-1');
      expect(notice.seenAt, seenAt);
      expect(acked.notifications.length, edited.state.notifications.length + 1);
      final notif = acked.notifications.singleWhere((n) => n.id == 'notif-ack');
      expect(notif.type, NotificationType.changeSeen);
      expect(notif.text, 'Rafi melihat perubahan jadwal Nonton film');
      expect(notif.at, seenAt);
      expect(notif.read, isFalse);
    });
  });
}
