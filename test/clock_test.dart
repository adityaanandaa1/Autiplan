import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/data/repository.dart';
import 'package:autiplan/data/seed.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements AutiPlanRepository {
  @override
  Future<AppState?> load() async => null;
  @override
  Future<void> save(AppState state) async {}
  @override
  Future<void> reset() async {}
}

void main() {
  group('Clock mengikuti Settings.demoClockEnabled (HANDOFF 7.1)', () {
    ProviderContainer containerWith({required bool demo}) {
      final seed = buildSeedState();
      final state = seed.copyWith(
        settings: seed.settings.copyWith(demoClockEnabled: demo),
      );
      return ProviderContainer(
        overrides: [
          appStateProvider.overrideWith(
            (ref) => AppStateNotifier(_FakeRepository(), state),
          ),
        ],
      );
    }

    test('demo aktif: now() terkunci Jumat 1 Mei 2026 16.00', () {
      final container = containerWith(demo: true);
      addTearDown(container.dispose);
      expect(container.read(clockProvider).now, DateTime(2026, 5, 1, 16, 0));
    });

    test('demo dimatikan: now() memakai jam sistem', () {
      final container = containerWith(demo: false);
      addTearDown(container.dispose);
      final before = DateTime.now();
      final now = container.read(clockProvider).now;
      expect(now.isBefore(before), isFalse);
      expect(now, isNot(DateTime(2026, 5, 1, 16, 0)));
    });

    test('mengubah pengaturan langsung mengubah clock', () {
      final container = containerWith(demo: true);
      addTearDown(container.dispose);
      final notifier = container.read(appStateProvider.notifier);
      notifier.updateState(
        container
            .read(appStateProvider)
            .copyWith(
              settings: container
                  .read(appStateProvider)
                  .settings
                  .copyWith(demoClockEnabled: false),
            ),
      );
      expect(container.read(clockProvider).demoClockEnabled, isFalse);
    });
  });
}
