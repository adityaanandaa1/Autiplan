import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';

/// Monday of the week containing [date], without the time.
DateTime mondayOf(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

// Pakai `read`, bukan `watch`: StateProvider dibuat ulang saat dependensinya
// berubah, sehingga pilihan pengguna akan hilang pada setiap tick jam.

/// Provider tanggal terpilih di layar Jadwal
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return ref.read(currentDayProvider);
});

/// Provider awal minggu (Senin)
final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  return mondayOf(ref.read(currentDayProvider));
});
