import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';

/// A clock abstraction that can be locked to a fixed time for demo mode.
///
/// When [demoClockEnabled] is true, [now] returns
/// Friday, May 1, 2026, 16:00 local time and does NOT advance.
class Clock {
  const Clock({this.demoClockEnabled = true});

  final bool demoClockEnabled;

  /// The fixed demo time: Friday, 1 May 2026, 16:00 local.
  static final DateTime demoTime = DateTime(2026, 5, 1, 16, 0);

  DateTime get now => demoClockEnabled ? demoTime : DateTime.now();

  Clock copyWith({bool? demoClockEnabled}) {
    return Clock(demoClockEnabled: demoClockEnabled ?? this.demoClockEnabled);
  }
}

/// Riverpod provider for the application clock.
///
/// Derived from `Settings.demoClockEnabled` so there is a single source of
/// truth for demo mode.
final clockProvider = Provider<Clock>((ref) {
  final demo = ref.watch(
    appStateProvider.select((s) => s.settings.demoClockEnabled),
  );
  return Clock(demoClockEnabled: demo);
});
