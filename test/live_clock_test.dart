import 'support/test_session.dart';
import 'dart:async';
import 'support/in_memory_repository.dart';

import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/caregiver/home_screen.dart';
import 'package:autiplan/features/caregiver/schedule_providers.dart';
import 'package:autiplan/features/caregiver/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fixture_state.dart';

/// Menyusun aplikasi dengan tick terkendali dan `clockProvider` yang meniru
/// produksi (instance baru tiap tick), sambil membaca jam dari [readNow].
Future<({ProviderContainer container, StreamController<int> ticks})> _pump(
  WidgetTester tester,
  Widget home,
  DateTime Function() readNow,
) async {
  await initializeDateFormatting('id_ID');
  final ticks = StreamController<int>();
  addTearDown(ticks.close);
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWithValue(testCaregiverSession),
      minuteTickProvider.overrideWith((ref) => ticks.stream),
      clockProvider.overrideWith((ref) {
        ref.watch(minuteTickProvider);
        return Clock(readNow);
      }),
      appStateProvider.overrideWith(
        (ref) => AppStateNotifier(InMemoryRepository(), buildFixtureState()),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(home: home),
    ),
  );
  await tester.pump();
  return (container: container, ticks: ticks);
}

Future<void> _tick(WidgetTester tester, StreamController<int> ticks) async {
  ticks.add(0);
  await tester.pump();
  await tester.pump();
}

void main() {
  test('clockProvider asli memberi tahu pendengar pada setiap tick', () async {
    final ticks = StreamController<int>();
    addTearDown(ticks.close);
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWithValue(testCaregiverSession),
        minuteTickProvider.overrideWith((ref) => ticks.stream),
      ],
    );
    addTearDown(container.dispose);

    var notified = 0;
    container.listen(clockProvider, (_, _) => notified++);
    for (var i = 0; i < 3; i++) {
      ticks.add(i);
      await pumpEventQueue();
    }

    expect(notified, greaterThanOrEqualTo(3));
  });

  test('tick tidak mengembalikan tanggal pilihan pengguna', () async {
    final ticks = StreamController<int>();
    addTearDown(ticks.close);
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWithValue(testCaregiverSession),
        minuteTickProvider.overrideWith((ref) => ticks.stream),
      ],
    );
    addTearDown(container.dispose);
    container.listen(selectedDateProvider, (_, _) {});
    container.listen(selectedWeekStartProvider, (_, _) {});

    final pickedDate = DateTime(2030, 1, 15);
    final pickedWeek = DateTime(2030, 1, 14);
    container.read(selectedDateProvider.notifier).state = pickedDate;
    container.read(selectedWeekStartProvider.notifier).state = pickedWeek;
    ticks.add(1);
    await pumpEventQueue();

    expect(container.read(selectedDateProvider), pickedDate);
    expect(container.read(selectedWeekStartProvider), pickedWeek);
  });

  testWidgets('Beranda berpindah ke SEKARANG tanpa aksi pengguna', (
    tester,
  ) async {
    var now = DateTime(2026, 5, 1, 15, 59);
    final app = await _pump(tester, const CaregiverHomeScreen(), () => now);
    expect(find.textContaining('SEKARANG'), findsNothing);

    now = DateTime(2026, 5, 1, 16, 0);
    await _tick(tester, app.ticks);

    expect(find.textContaining('SEKARANG'), findsWidgets);
    expect(find.textContaining('Sepeda Santai'), findsWidgets);
  });

  testWidgets('Jadwal mengikuti hari baru bila sedang melihat hari ini', (
    tester,
  ) async {
    var now = DateTime(2026, 5, 3, 23, 59);
    final app = await _pump(tester, const CaregiverScheduleScreen(), () => now);

    now = DateTime(2026, 5, 4, 0, 1);
    await _tick(tester, app.ticks);

    expect(app.container.read(selectedDateProvider), DateTime(2026, 5, 4));
    expect(app.container.read(selectedWeekStartProvider), DateTime(2026, 5, 4));
  });

  testWidgets('Jadwal tetap di tanggal lain yang sedang dilihat', (
    tester,
  ) async {
    var now = DateTime(2026, 5, 1, 23, 59);
    final app = await _pump(tester, const CaregiverScheduleScreen(), () => now);
    final picked = DateTime(2026, 4, 29);
    app.container.read(selectedDateProvider.notifier).state = picked;
    await tester.pump();

    now = DateTime(2026, 5, 2, 0, 1);
    await _tick(tester, app.ticks);

    expect(app.container.read(selectedDateProvider), picked);
  });
}
