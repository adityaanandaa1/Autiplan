import 'package:autiplan/core/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clock', () {
    test('Clock(() => t).now == t', () {
      final t = DateTime(2026, 5, 1, 16, 0);
      expect(Clock(() => t).now, t);
    });

    test('Clock bawaan memakai jam sistem', () {
      final before = DateTime.now();
      final now = const Clock().now;
      expect(now.isBefore(before), isFalse);
    });

    test('clockProvider bisa di-override', () {
      final t = DateTime(2026, 5, 1, 15, 59);
      final container = ProviderContainer(
        overrides: [clockProvider.overrideWithValue(Clock(() => t))],
      );
      addTearDown(container.dispose);
      expect(container.read(clockProvider).now, t);
    });
  });
}
