import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';

/// Provider tanggal terpilih di layar Jadwal
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  return DateTime(clock.now.year, clock.now.month, clock.now.day);
});

/// Provider awal minggu (Senin)
final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  final clock = ref.watch(clockProvider);
  final today = clock.now;
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
});
