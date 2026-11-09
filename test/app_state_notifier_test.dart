import 'dart:async';

import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/providers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_state.dart';
import 'support/in_memory_repository.dart';

class _FailingWatchRepository extends InMemoryRepository {
  @override
  Stream<AppState> watch() => Stream.error(StateError('permission-denied'));
}

void main() {
  late AppState base;

  setUp(() => base = buildFixtureState());

  AppState renamed(AppState s) =>
      s.copyWith(settings: s.settings.copyWith(caregiverName: 'Nama Baru'));

  test('updateState mengubah state seketika walau apply belum selesai', () {
    final repo = InMemoryRepository()..applyGate = Completer<void>();
    final notifier = AppStateNotifier(repo, AppState.empty());

    notifier.updateState(base);

    expect(notifier.state, base);
    expect(repo.applied, hasLength(1));
    expect(repo.applied.single.$1, AppState.empty());
    expect(repo.applied.single.$2, base);
  });

  test('galat apply tidak dilempar ke jalur UI dan state tetap', () async {
    final repo = InMemoryRepository()..applyError = StateError('offline');
    final notifier = AppStateNotifier(repo, AppState.empty());

    notifier.updateState(base);
    await Future<void>.delayed(Duration.zero);

    expect(notifier.state, base);
  });

  test('ready langsung selesai bila start tidak dipanggil', () async {
    final notifier = AppStateNotifier(InMemoryRepository(), base);
    await notifier.ready;
  });

  test('start: ready selesai setelah emisi pertama dan state terisi', () async {
    final repo = InMemoryRepository(base);
    final notifier = AppStateNotifier(repo, AppState.empty());
    var done = false;

    notifier.start();
    unawaited(notifier.ready.then((_) => done = true));
    expect(done, isFalse);

    await notifier.ready;
    expect(notifier.state, base);
  });

  test(
    'start: perubahan dari HP lain mengubah state tanpa ditulis balik',
    () async {
      final repo = InMemoryRepository(base);
      final notifier = AppStateNotifier(repo, AppState.empty())..start();
      await notifier.ready;

      repo.emitRemote(renamed(base));
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.settings.caregiverName, 'Nama Baru');
      expect(repo.applied, isEmpty);
    },
  );

  test('dispose membatalkan langganan watch', () async {
    final repo = InMemoryRepository(base);
    final notifier = AppStateNotifier(repo, AppState.empty())..start();
    await notifier.ready;
    notifier.dispose();

    repo.emitRemote(renamed(base));
    await Future<void>.delayed(Duration.zero);
    expect(notifier.mounted, isFalse);
  });

  test('galat watch dicatat dan ready tetap selesai', () async {
    final notifier = AppStateNotifier(
      _FailingWatchRepository(),
      AppState.empty(),
    )..start();
    await notifier.ready;
    expect(notifier.state, AppState.empty());
  });
}
