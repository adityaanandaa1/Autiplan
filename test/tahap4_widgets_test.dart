import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/core/widgets/activity_icon_data.dart';
import 'package:autiplan/core/widgets/caregiver_header.dart';
import 'package:autiplan/core/widgets/caregiver_nav_bar.dart';
import 'package:autiplan/core/widgets/change_notice_card.dart';
import 'package:autiplan/core/widgets/suggestion_card.dart';
import 'package:autiplan/core/widgets/week_strip.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/seed.dart';
import 'package:autiplan/domain/suggestion_engine.dart';
import 'package:autiplan/features/caregiver/caregiver_shell.dart';
import 'package:autiplan/features/caregiver/home_screen.dart';
import 'package:autiplan/features/caregiver/notifications_screen.dart';
import 'package:autiplan/features/caregiver/schedule_providers.dart';
import 'package:autiplan/features/caregiver/schedule_screen.dart';
import 'package:autiplan/features/caregiver/suggestions_screen.dart';
import 'package:autiplan/features/caregiver/widgets/current_activity_card.dart';
import 'package:autiplan/features/caregiver/widgets/schedule_activity_rows.dart';
import 'package:autiplan/features/caregiver/widgets/suggestion_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget screen, {
  AppState? state,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await initializeDateFormatting('id_ID');
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(theme: buildParentTheme(), home: screen),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byWidget(screen)),
  );
  if (state != null) {
    container.read(appStateProvider.notifier).updateState(state);
    await tester.pump();
  }
  return container;
}

ChangeNotice _notice(
  String id,
  DateTime sentAt, {
  DateTime? seenAt,
  bool deleted = false,
}) => ChangeNotice(
  id: id,
  childId: 'child-rafi',
  activityId: 'a-$id',
  before: const ActivitySnapshot(
    shortTitle: 'Les',
    title: 'Les dengan Pak Lana',
    icon: ActivityIcon.les,
    start: TimeOfDayLite(20, 0),
  ),
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

Activity _act(
  String id,
  String title,
  ActivityIcon icon,
  TimeOfDayLite start,
  TimeOfDayLite? end,
) => Activity(
  id: id,
  childId: 'child-rafi',
  title: title,
  shortTitle: title,
  icon: icon,
  date: DateTime(2026, 5, 1),
  start: start,
  end: end,
);

void main() {
  final seed = buildSeedState();
  final today = Clock.demoTime;

  group('A5/A7 CaregiverHeader', () {
    testWidgets('titik notifikasi berwarna utama, bukan bahaya', (t) async {
      await _pump(
        t,
        const Scaffold(
          body: CaregiverHeader(title: 'X', showBell: true, bellHasBadge: true),
        ),
      );
      final dot = t.widget<Container>(find.byKey(CaregiverHeader.bellBadgeKey));
      expect((dot.decoration! as BoxDecoration).color, AppColors.utama);
    });

    testWidgets('area sentuh tombol kembali dan lonceng minimal 48x48', (
      t,
    ) async {
      await _pump(
        t,
        Scaffold(
          body: CaregiverHeader(
            title: 'X',
            variant: CaregiverHeaderVariant.back,
            onBack: () {},
            showBell: true,
            onBellTap: () {},
          ),
        ),
      );
      final buttons = find.byType(IconButton);
      expect(buttons, findsNWidgets(2));
      for (final b in buttons.evaluate()) {
        final size = t.getSize(find.byWidget(b.widget));
        expect(size.width, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
        expect(size.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
      }
    });
  });

  group('A2 satu pil Sekarang', () {
    testWidgets('dua kegiatan berlangsung: hanya start terakhir', (t) async {
      final state = seed.copyWith(
        activities: [
          _act(
            'a1',
            'Main Lama',
            ActivityIcon.main,
            const TimeOfDayLite(15, 0),
            const TimeOfDayLite(17, 0),
          ),
          _act(
            'a2',
            'Sepeda Baru',
            ActivityIcon.sepeda,
            const TimeOfDayLite(16, 0),
            const TimeOfDayLite(17, 0),
          ),
        ],
      );
      late List<Widget> rows;
      await _pump(
        t,
        Builder(
          builder: (context) {
            rows = buildScheduleActivityRows(
              context: context,
              activities: state.activities,
              selectedDate: DateTime(2026, 5, 1),
              now: today,
              state: state,
              child: state.children.first,
            );
            return Scaffold(body: Column(children: rows));
          },
        ),
      );
      expect(find.text('Sekarang'), findsOneWidget);
      final pillRow = find.ancestor(
        of: find.text('Sekarang'),
        matching: find.byKey(const ValueKey('a2')),
      );
      expect(pillRow, findsOneWidget);
    });

    testWidgets(
      'kegiatan non-Tidur tanpa selesai tidak menampilkan teks "Pagi"',
      (t) async {
        final state = seed.copyWith(
          activities: [
            _act(
              'main',
              'Main Sore',
              ActivityIcon.main,
              const TimeOfDayLite(15, 30),
              null,
            ),
          ],
        );
        await _pump(
          t,
          Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: buildScheduleActivityRows(
                  context: context,
                  activities: state.activities,
                  selectedDate: DateTime(2026, 5, 1),
                  now: today,
                  state: state,
                  child: state.children.first,
                ),
              ),
            ),
          ),
        );
        expect(find.text('Sekarang'), findsOneWidget);
        expect(find.textContaining('Pagi'), findsNothing);
      },
    );
  });

  group('B3 ChangeNoticeCard', () {
    Future<void> pumpCard(WidgetTester t, ChangeNoticeCard card) =>
        _pump(t, Scaffold(body: card));

    testWidgets('belum dibuka', (t) async {
      await pumpCard(
        t,
        const ChangeNoticeCard(
          childName: 'Rafi',
          hasUnread: true,
          changeLine: 'Les → Nonton film, 20.30',
          otherCount: 2,
        ),
      );
      expect(find.text('Perubahan terkirim ke Rafi'), findsOneWidget);
      expect(find.text('Les → Nonton film, 20.30'), findsOneWidget);
      expect(find.text('Belum dibuka Rafi'), findsOneWidget);
      expect(find.text('+2 perubahan lain'), findsOneWidget);
      expect(find.byIcon(LucideIcons.refreshCw), findsOneWidget);
      final pill = t.widget<Container>(
        find
            .ancestor(
              of: find.text('Belum dibuka Rafi'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((pill.decoration! as BoxDecoration).color, AppColors.saranLembut);
    });

    testWidgets('dilihat', (t) async {
      await pumpCard(
        t,
        ChangeNoticeCard(
          childName: 'Rafi',
          hasUnread: false,
          seenAt: DateTime(2026, 5, 1, 16, 5),
          changeLine: 'Les → Nonton film, 20.30',
        ),
      );
      expect(find.text('Dilihat Rafi pukul 16.05'), findsOneWidget);
      expect(find.textContaining('perubahan lain'), findsNothing);
      final pill = t.widget<Container>(
        find
            .ancestor(
              of: find.text('Dilihat Rafi pukul 16.05'),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((pill.decoration! as BoxDecoration).color, AppColors.suksesLembut);
    });
  });

  group('B4 SuggestionCard label', () {
    testWidgets('memakai label yang diberikan', (t) async {
      await _pump(
        t,
        const Scaffold(
          body: SuggestionCard(
            label: 'Saran untuk Rafi · 1 dari 3',
            content: 'isi',
            actionLabel: 'Lihat semua saran',
          ),
        ),
      );
      expect(find.text('Saran untuk Rafi · 1 dari 3'), findsOneWidget);
    });
  });

  group('Beranda (B1, B2, B3, B4, A3, A5)', () {
    testWidgets('sapaan, tanggal, kartu Sekarang, progres', (t) async {
      await _pump(t, const CaregiverHomeScreen());
      expect(find.text('Selamat sore, Bu Sari'), findsOneWidget);
      expect(find.text('Jumat, 1 Mei 2026'), findsOneWidget);
      expect(find.text('SEKARANG · RAFI'), findsOneWidget);
      expect(find.text('Sepeda Santai'), findsOneWidget);
      expect(find.text('16.00 – 17.00'), findsOneWidget);
      expect(find.text('1 dari 5 kegiatan hari ini selesai'), findsOneWidget);
      expect(
        find.text('Semua jadwal berjalan sesuai rencana.'),
        findsOneWidget,
      );
      final tile = t.getSize(find.byKey(CurrentActivityCard.iconTileKey));
      expect(tile, const Size(44, 44));
    });

    testWidgets('kartu saran berlabel "1 dari n"', (t) async {
      await _pump(t, const CaregiverHomeScreen());
      final n = generateSuggestions(seed, today, 'child-rafi').length;
      expect(find.text('Saran untuk Rafi · 1 dari $n'), findsOneWidget);
    });

    testWidgets('Sekarang memilih kegiatan dengan start paling akhir', (
      t,
    ) async {
      final state = seed.copyWith(
        activities: [
          _act(
            'a1',
            'Main Lama',
            ActivityIcon.main,
            const TimeOfDayLite(15, 0),
            const TimeOfDayLite(17, 0),
          ),
          _act(
            'a2',
            'Sepeda Baru',
            ActivityIcon.sepeda,
            const TimeOfDayLite(16, 0),
            const TimeOfDayLite(17, 0),
          ),
        ],
      );
      await _pump(t, const CaregiverHomeScreen(), state: state);
      expect(find.text('Sepeda Baru'), findsOneWidget);
      expect(find.text('Main Lama'), findsNothing);
    });

    testWidgets('perlu perhatian: status dari notice terbaru, +n lain', (
      t,
    ) async {
      // Terbaru sudah dilihat, yang lama belum: status harus "Dilihat".
      final state = seed.copyWith(
        notices: [
          _notice('a', DateTime(2026, 5, 1, 9, 0)),
          _notice(
            'b',
            DateTime(2026, 5, 1, 15, 0),
            seenAt: DateTime(2026, 5, 1, 15, 30),
          ),
        ],
      );
      await _pump(t, const CaregiverHomeScreen(), state: state);
      expect(find.text('Perubahan terkirim ke Rafi'), findsOneWidget);
      expect(find.text('Dilihat Rafi pukul 15.30'), findsOneWidget);
      expect(find.text('Belum dibuka Rafi'), findsNothing);
      expect(find.text('+1 perubahan lain'), findsOneWidget);
      expect(
        find.text('Les dengan Pak Lana → Nonton film, 20.30'),
        findsOneWidget,
      );
    });

    testWidgets('notice hapus ditangani', (t) async {
      final state = seed.copyWith(
        notices: [_notice('a', DateTime(2026, 5, 1, 9, 0), deleted: true)],
      );
      await _pump(t, const CaregiverHomeScreen(), state: state);
      expect(
        find.text('Les dengan Pak Lana → Waktu bebas, 20.00'),
        findsOneWidget,
      );
      expect(find.text('Belum dibuka Rafi'), findsOneWidget);
    });
  });

  group('Jadwal (A1, A6, A8, B4, B9)', () {
    testWidgets('lonceng Jadwal memakai titik notifikasi', (t) async {
      await _pump(t, const CaregiverScheduleScreen());
      expect(find.byKey(CaregiverHeader.bellBadgeKey), findsOneWidget);
    });

    testWidgets('saran hari kosong sesuai tanggal terpilih', (t) async {
      final c = await _pump(t, const CaregiverScheduleScreen());
      c.read(selectedDateProvider.notifier).state = DateTime(2026, 5, 3);
      await t.pump();
      expect(find.text('Saran untuk hari kosong'), findsOneWidget);
      expect(find.textContaining('Minggu masih kosong'), findsOneWidget);
      expect(find.textContaining('Sabtu masih kosong'), findsNothing);
      c.read(selectedDateProvider.notifier).state = DateTime(2026, 5, 2);
      await t.pump();
      expect(find.textContaining('Sabtu masih kosong'), findsOneWidget);
    });

    testWidgets('geser strip minggu ikut mengubah tanggal terpilih', (t) async {
      final c = await _pump(t, const CaregiverScheduleScreen());
      await t.fling(find.byType(WeekStrip), const Offset(-300, 0), 1000);
      await t.pumpAndSettle();
      expect(c.read(selectedWeekStartProvider), DateTime(2026, 5, 4));
      expect(c.read(selectedDateProvider), DateTime(2026, 5, 8));
      expect(find.text('Mei 2026'), findsOneWidget);
    });
  });

  group('Saran (B5, B6)', () {
    testWidgets('catatan sesuai HANDOFF dan cek otomatis dari Settings', (
      t,
    ) async {
      await _pump(t, const CaregiverSuggestionsScreen());
      expect(
        find.text(
          'Saran dibuat dari pola jadwal dan profil Rafi. Bukan saran medis. '
          'Diskusikan dengan terapis bila ragu.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cek otomatis'), findsOneWidget);
      expect(find.text('Jeda transisi aman'), findsOneWidget);
      expect(
        find.text('Semua kegiatan hari ini punya jeda minimal 10 menit.'),
        findsOneWidget,
      );
      expect(find.text('Layar < 30 menit sebelum tidur'), findsNothing);
      expect(find.text('Hari kosong'), findsNothing);
    });

    testWidgets('cek otomatis hilang bila ada pemicu jeda', (t) async {
      final state = seed.copyWith(
        settings: seed.settings.copyWith(minGapMinutes: 20),
      );
      await _pump(t, const CaregiverSuggestionsScreen(), state: state);
      expect(find.text('Cek otomatis'), findsNothing);
      expect(find.text('Jeda transisi aman'), findsNothing);
    });
  });

  group('Notifikasi (A9, B8)', () {
    testWidgets('ikon kegiatan untuk activityStarted/activityDone', (t) async {
      await _pump(t, const CaregiverNotificationsScreen());
      expect(find.byIcon(lucideIconFor(ActivityIcon.sekolah)), findsOneWidget);
      expect(find.byIcon(lucideIconFor(ActivityIcon.sepeda)), findsOneWidget);
      expect(find.byIcon(LucideIcons.phone), findsOneWidget);
    });

    testWidgets('ubin darurat memakai token bahayaLembut', (t) async {
      await _pump(t, const CaregiverNotificationsScreen());
      final tiles = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == AppColors.bahayaLembut,
      );
      expect(tiles, findsOneWidget);
    });
  });

  group('B10 detail saran', () {
    testWidgets('ikon Lucide, kotak Kenapa saran ini? dengan Data/Dasar', (
      t,
    ) async {
      final s = generateSuggestions(
        seed,
        today,
        'child-rafi',
      ).firstWhere((s) => s.type == SuggestionType.independence);
      await _pump(
        t,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  showSuggestionDetailSheet(context, suggestion: s),
              child: const Text('buka'),
            ),
          ),
        ),
      );
      await t.tap(find.text('buka'));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
      expect(find.byIcon(LucideIcons.lightbulb), findsOneWidget);
      expect(find.text('Kenapa saran ini?'), findsOneWidget);
      expect(find.textContaining('Data: Sepeda Santai'), findsOneWidget);
      expect(find.textContaining('Dasar: Anak autis'), findsOneWidget);
      expect(
        find.text(
          'Rafi menyelesaikan Sepeda Santai tepat waktu 5 hari '
          'berturut-turut. Coba kurangi langkah instruksi dari 3 menjadi 1 '
          'supaya Rafi berlatih mandiri.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Bisa dikembalikan ke 3 langkah kapan saja.'),
        findsOneWidget,
      );
    });
  });

  group('B11 CaregiverNavBar', () {
    testWidgets('tab punya label semantik dan status terpilih', (t) async {
      final handle = t.ensureSemantics();
      await _pump(
        t,
        Scaffold(
          bottomNavigationBar: CaregiverNavBar(
            currentTab: CaregiverTab.schedule,
            onTabSelected: (_) {},
          ),
        ),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel('Jadwal')),
        isSemantics(label: 'Jadwal', isButton: true, isSelected: true),
      );
      expect(find.bySemanticsLabel('Beranda'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('CaregiverShell memakai CaregiverNavBar bersama', (t) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: '/a',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (c, s, shell) => CaregiverShell(navigationShell: shell),
            branches: [
              for (final p in ['/a', '/b', '/c'])
                StatefulShellBranch(
                  routes: [GoRoute(path: p, builder: (c, s) => Text('hal $p'))],
                ),
            ],
          ),
        ],
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp.router(
            theme: buildParentTheme(),
            routerConfig: router,
          ),
        ),
      );
      expect(find.byType(CaregiverNavBar), findsOneWidget);
      await t.tap(find.text('Jadwal'));
      await t.pumpAndSettle();
      expect(find.text('hal /b'), findsOneWidget);
    });
  });

  group('B2 CurrentActivityCard BERIKUTNYA', () {
    testWidgets('tanpa kegiatan sekarang: label BERIKUTNYA', (t) async {
      final state = seed.copyWith(
        activities: [
          _act(
            'n',
            'Ngaji Nanti',
            ActivityIcon.ngaji,
            const TimeOfDayLite(18, 0),
            const TimeOfDayLite(19, 0),
          ),
        ],
      );
      await _pump(t, const CaregiverHomeScreen(), state: state);
      expect(find.text('BERIKUTNYA · RAFI'), findsOneWidget);
      expect(find.text('Ngaji Nanti'), findsOneWidget);
    });
  });
}
