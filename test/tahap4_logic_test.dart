import 'package:autiplan/core/widgets/change_notice_card.dart';
import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:autiplan/domain/suggestion_engine.dart';
import 'package:autiplan/features/caregiver/home_screen.dart';
import 'package:autiplan/features/caregiver/notifications_screen.dart';
import 'package:autiplan/features/caregiver/schedule_screen.dart';
import 'package:flutter_test/flutter_test.dart';

ChangeNotice _notice(
  String id, {
  required DateTime sentAt,
  DateTime? seenAt,
  bool deleted = false,
}) {
  const before = ActivitySnapshot(
    shortTitle: 'Les',
    title: 'Les dengan Pak Lana',
    icon: ActivityIcon.les,
    start: TimeOfDayLite(20, 0),
  );
  return ChangeNotice(
    id: id,
    childId: 'child-rafi',
    activityId: 'a-$id',
    before: before,
    after: deleted
        ? null
        : const ActivitySnapshot(
            shortTitle: 'Nonton',
            title: 'Nonton film',
            icon: ActivityIcon.nonton,
            start: TimeOfDayLite(20, 30),
          ),
    message: 'pesan',
    sentAt: sentAt,
    seenAt: seenAt,
  );
}

void main() {
  final now = fixtureNow;

  group('A1 emptyDaySuggestionForDate', () {
    test('hanya mengembalikan saran untuk tanggal yang dipilih', () {
      final state = buildFixtureState();
      final all = generateSuggestions(state, now, 'child-rafi');
      final sat = emptyDaySuggestionForDate(all, DateTime(2026, 5, 2));
      final sun = emptyDaySuggestionForDate(all, DateTime(2026, 5, 3));
      expect(sat, isNotNull);
      expect(sat!.payload['date'], '2026-05-02');
      expect(sun!.payload['date'], '2026-05-03');
      expect(emptyDaySuggestionForDate(all, DateTime(2026, 5, 1)), isNull);
    });
  });

  group('A8 shiftWeek', () {
    test('geser minggu ikut menggeser tanggal terpilih (hari yang sama)', () {
      final r = shiftWeek(DateTime(2026, 4, 27), DateTime(2026, 5, 1), 1);
      expect(r.weekStart, DateTime(2026, 5, 4));
      expect(r.selectedDate, DateTime(2026, 5, 8));
      final back = shiftWeek(DateTime(2026, 4, 27), DateTime(2026, 5, 1), -1);
      expect(back.weekStart, DateTime(2026, 4, 20));
      expect(back.selectedDate, DateTime(2026, 4, 24));
    });
  });

  group('B1 sapaan', () {
    test('batas waktu pagi/siang/sore/malam', () {
      String g(int h, [int m = 0]) =>
          caregiverGreeting(DateTime(2026, 5, 1, h, m), 'Bu Sari');
      expect(g(3, 59), 'Selamat malam, Bu Sari');
      expect(g(4), 'Selamat pagi, Bu Sari');
      expect(g(10, 59), 'Selamat pagi, Bu Sari');
      expect(g(11), 'Selamat siang, Bu Sari');
      expect(g(14, 59), 'Selamat siang, Bu Sari');
      expect(g(15), 'Selamat sore, Bu Sari');
      expect(g(17, 59), 'Selamat sore, Bu Sari');
      expect(g(18), 'Selamat malam, Bu Sari');
      expect(g(0), 'Selamat malam, Bu Sari');
    });
  });

  group('B3 ringkasan notice', () {
    final t = DateTime(2026, 5, 1, 15, 0);
    test('memakai notice terbaru dan menghitung sisanya', () {
      final older = _notice(
        'a',
        sentAt: t,
        seenAt: DateTime(2026, 5, 1, 15, 5),
      );
      final latest = _notice('b', sentAt: t.add(const Duration(minutes: 30)));
      final s = summarizeNotices([older, latest])!;
      expect(s.latest.id, 'b');
      expect(s.otherCount, 1);
      expect(summarizeNotices(const []), isNull);
    });

    test('baris perubahan: lama -> baru, jam; hapus -> Waktu bebas', () {
      expect(
        noticeChangeLine(_notice('a', sentAt: t)),
        'Les dengan Pak Lana → Nonton film, 20.30',
      );
      expect(
        noticeChangeLine(_notice('a', sentAt: t, deleted: true)),
        'Les dengan Pak Lana → Waktu bebas, 20.00',
      );
    });
  });

  group('B6 transitionGapAllClear', () {
    test('seed: aman', () {
      expect(
        transitionGapAllClear(buildFixtureState(), now, 'child-rafi'),
        isTrue,
      );
    });

    test('ada pemicu (walau saran diabaikan): tidak aman', () {
      final seed = buildFixtureState();
      final state = seed.copyWith(
        settings: seed.settings.copyWith(minGapMinutes: 20),
      );
      expect(transitionGapAllClear(state, now, 'child-rafi'), isFalse);
      final dismissed = state.copyWith(
        suggestionStatus: {
          for (final s in generateSuggestions(state, now, 'child-rafi'))
            if (s.type == SuggestionType.transitionGap)
              s.id: SuggestionStatus.dismissed,
        },
      );
      expect(transitionGapAllClear(dismissed, now, 'child-rafi'), isFalse);
    });

    test('hari tanpa kegiatan: tidak ditampilkan', () {
      expect(
        transitionGapAllClear(
          buildFixtureState().copyWith(activities: const []),
          now,
          'child-rafi',
        ),
        isFalse,
      );
    });
  });

  group('A9 ikon notifikasi', () {
    test('diturunkan dari judul kegiatan pada teks', () {
      final state = buildFixtureState();
      NotificationType.values;
      CaregiverNotification n(NotificationType type, String text) =>
          CaregiverNotification(
            id: 'x',
            type: type,
            text: text,
            at: now,
            read: false,
          );
      expect(
        notificationActivityIcon(
          n(NotificationType.activityDone, 'Rafi menyelesaikan Sekolah'),
          state,
        ),
        ActivityIcon.sekolah,
      );
      expect(
        notificationActivityIcon(
          n(NotificationType.activityStarted, 'Rafi mulai Sepeda Santai'),
          state,
        ),
        ActivityIcon.sepeda,
      );
      expect(
        notificationActivityIcon(
          n(NotificationType.activityStarted, 'Rafi mulai Tidak Dikenal'),
          state,
        ),
        isNull,
      );
    });
  });
}
