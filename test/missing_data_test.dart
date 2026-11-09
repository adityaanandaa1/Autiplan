import 'package:autiplan/core/clock.dart';
import 'package:autiplan/core/theme/theme.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:autiplan/features/caregiver/widgets/add_activity_sheet.dart';
import 'package:autiplan/features/child/child_activity_screen.dart';
import 'package:autiplan/features/child/child_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';
import 'tahap5_helpers.dart';

/// Data bisa berubah atau terhapus dari HP lain, jadi pencarian anak,
/// kegiatan, dan notice tidak boleh melempar saat datanya hilang.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  late AppState base;
  setUp(() => base = buildFixtureState());

  ChangeNotice noticeFor(String childId) => ChangeNotice(
    id: 'notice-1',
    childId: childId,
    activityId: base.activities.first.id,
    before: const ActivitySnapshot(
      shortTitle: 'Les',
      title: 'Les',
      icon: ActivityIcon.sepeda,
      start: TimeOfDayLite(16, 0),
    ),
    message: 'Jam berubah.',
    sentAt: fixtureNow,
  );

  group('acknowledgeNotice', () {
    test(
      'anak sudah dihapus: notice tetap ditandai dilihat, tanpa notifikasi',
      () {
        final state = base.copyWith(notices: [noticeFor('child-hilang')]);
        final result = acknowledgeNotice(
          state: state,
          noticeId: 'notice-1',
          now: fixtureNow,
          notificationId: 'n-1',
        );
        expect(result.notices.single.seenAt, fixtureNow);
        expect(result.notifications, state.notifications);
      },
    );

    test('notice sudah dihapus: state tidak berubah', () {
      final result = acknowledgeNotice(
        state: base,
        noticeId: 'tidak-ada',
        now: fixtureNow,
        notificationId: 'n-1',
      );
      expect(result, base);
    });
  });

  group('completeActivity', () {
    test('anak sudah dihapus: completion tetap dibuat, tanpa notifikasi', () {
      final orphan = base.activities.first.copyWith(childId: 'child-hilang');
      final result = completeActivity(
        state: base.copyWith(activities: [orphan]),
        activity: orphan,
        stepsChecked: const [],
        now: fixtureNow,
        completionId: 'c-1',
        notificationId: 'n-1',
      );
      expect(result.completion.activityId, orphan.id);
      expect(result.state.completions.length, base.completions.length + 1);
      expect(result.state.notifications, base.notifications);
    });
  });

  group('layar', () {
    testWidgets('form Tambah menutup diri bila anaknya terhapus', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (c, s) =>
            AddActivitySheet(childId: rafiOf(s).id, initialDate: fixtureNow),
      );
      expect(find.text('Tambah jadwal'), findsOneWidget);

      host.setState(
        host.state.copyWith(
          children: host.state.children
              .where((c) => c.id != 'child-rafi')
              .toList(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tambah jadwal'), findsNothing);
    });

    for (final entry in <String, Widget Function()>{
      'ChildActivityScreen': () =>
          const ChildActivityScreen(activityId: 'hilang'),
      'ChildSuccessScreen': () =>
          const ChildSuccessScreen(activityId: 'hilang'),
    }.entries) {
      testWidgets('${entry.key}: kegiatan hilang -> kembali ke beranda anak', (
        tester,
      ) async {
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => entry.value()),
            GoRoute(
              path: '/anak',
              builder: (_, _) => const Text('beranda anak'),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              clockProvider.overrideWithValue(Clock(() => fixtureNow)),
              appStateProvider.overrideWith(
                (ref) => AppStateNotifier(InMemoryRepository(), base),
              ),
            ],
            child: MaterialApp.router(
              theme: buildParentTheme(childPalette: ChildPalette.lautTenang),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('beranda anak'), findsOneWidget);
      });
    }
  });
}
