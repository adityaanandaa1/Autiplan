import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A clock abstraction that can be replaced in tests.
///
/// Defaults to [DateTime.now]. Pass a callback to lock the time.
class Clock {
  const Clock([this._now = DateTime.now]);

  final DateTime Function() _now;

  DateTime get now => _now();
}

/// Emits every 30 seconds so widgets that show "Sekarang" refresh when the
/// hour or day changes while the app stays open.
final minuteTickProvider = StreamProvider.autoDispose<int>((ref) {
  return Stream<int>.periodic(const Duration(seconds: 30), (i) => i);
});

/// Riverpod provider for the application clock.
///
/// Watches [minuteTickProvider] so dependents rebuild on each tick.
final clockProvider = Provider<Clock>((ref) {
  ref.watch(minuteTickProvider);
  // Harus instance baru: Riverpod tidak memberi tahu pendengar bila nilainya
  // identik, jadi `const Clock()` membuat layar tidak pernah diperbarui.
  return Clock(() => DateTime.now());
});

/// Today's date without the time. Only notifies when the day changes.
final currentDayProvider = Provider<DateTime>((ref) {
  final now = ref.watch(clockProvider).now;
  return DateTime(now.year, now.month, now.day);
});
