import 'dart:io';

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
///
/// Under `flutter test` (`FLUTTER_TEST` set), returns an empty stream so
/// widget tests do not leave a pending periodic timer.
final minuteTickProvider = StreamProvider.autoDispose<int>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return const Stream<int>.empty();
  }
  return Stream<int>.periodic(const Duration(seconds: 30), (i) => i);
});

/// Riverpod provider for the application clock.
///
/// Watches [minuteTickProvider] so dependents rebuild on each tick.
final clockProvider = Provider<Clock>((ref) {
  ref.watch(minuteTickProvider);
  return const Clock();
});
