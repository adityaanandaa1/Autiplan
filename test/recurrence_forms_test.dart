import 'package:autiplan/core/widgets/buttons.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/domain/recurrence.dart';
import 'package:autiplan/features/caregiver/widgets/add_activity_sheet.dart';
import 'package:autiplan/features/caregiver/widgets/edit_activity_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_state.dart';
import 'tahap5_helpers.dart';

Future<void> _tap(WidgetTester tester, String label) async {
  final f = find.widgetWithText(PrimaryButton, label);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('Form Tambah kegiatan berulang', () {
    testWidgets('hari ulang dipilih -> seriesId sama dengan ID kegiatan', (
      tester,
    ) async {
      final host = await pumpSheet(
        tester,
        (c, s) => AddActivitySheet(
          childId: rafiOf(s).id,
          initialDate: fixtureNow,
          initialTitle: 'Gosok Gigi',
          initialIcon: ActivityIcon.mandi,
          initialStart: const TimeOfDayLite(6, 0),
          initialEnd: const TimeOfDayLite(6, 15),
        ),
      );
      await tapText(tester, 'Langkah & pengulangan');
      await tapText(tester, 'Sen');
      await _tap(tester, 'Simpan jadwal');

      final saved = activityTitled(host.state, 'Gosok Gigi');
      expect(saved.repeatWeekdays, {1});
      expect(saved.seriesId, saved.id);
    });

    testWidgets('tanpa hari ulang -> seriesId null', (tester) async {
      final host = await pumpSheet(
        tester,
        (c, s) => AddActivitySheet(
          childId: rafiOf(s).id,
          initialDate: fixtureNow,
          initialTitle: 'Gosok Gigi',
          initialIcon: ActivityIcon.mandi,
          initialStart: const TimeOfDayLite(6, 0),
          initialEnd: const TimeOfDayLite(6, 15),
        ),
      );
      await _tap(tester, 'Simpan jadwal');
      expect(activityTitled(host.state, 'Gosok Gigi').seriesId, isNull);
    });
  });

  group('Form Ubah kegiatan berulang', () {
    testWidgets('mengubah hari ulang membuang kemunculan sesudahnya saja', (
      tester,
    ) async {
      final base = buildFixtureState();
      final template = base.activities.firstWhere(
        (a) => a.title == 'Sepeda Santai',
      );
      final first = template.copyWith(
        id: 'sr_20260501',
        date: DateTime(2026, 5, 1),
        seriesId: 'sr',
        repeatWeekdays: {5},
      );
      final series = materializeRecurring(
        [first],
        DateTime(2026, 5, 1),
        horizonDays: 21,
      );
      expect(series.length, 4); // 1, 8, 15, 22 Mei
      final initial = base.copyWith(
        activities: [
          ...base.activities.where((a) => a.title != 'Sepeda Santai'),
          ...series,
        ],
      );

      final host = await pumpSheet(
        tester,
        (c, s) => EditActivitySheet(
          activity: series[1], // 8 Mei
          child: rafiOf(s),
        ),
        initial: initial,
      );
      await tapText(tester, 'Langkah & pengulangan');
      await tapText(tester, 'Jum'); // matikan Jumat
      await _tap(tester, 'Simpan');

      final remaining = host.state.activities
          .where((a) => a.seriesId == 'sr')
          .map((a) => a.id)
          .toList();
      expect(remaining, ['sr_20260501', 'sr_20260508']);
      expect(
        host.state.activities.firstWhere((a) => a.id == 'sr_20260508').seriesId,
        'sr',
      );
    });
  });
}
