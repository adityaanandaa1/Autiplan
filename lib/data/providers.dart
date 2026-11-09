import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../domain/recurrence.dart';
import 'local_repository.dart';
import 'models/models.dart';
import 'repository.dart';

/// Provider for SharedPreferences instance. Must be overridden in main().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provider for AutiPlanRepository.
final repositoryProvider = Provider<AutiPlanRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalRepository(prefs);
});

/// StateNotifier for managing the global AppState.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(
    this._repository,
    AppState initial, {
    AppState Function(AppState)? normalize,
  }) : _normalize = normalize,
       super(normalize == null ? initial : normalize(initial));

  final AutiPlanRepository _repository;

  /// Dipakai pada setiap perubahan, mis. memperluas kegiatan berulang.
  final AppState Function(AppState)? _normalize;

  /// Update the state and persist to repository asynchronously.
  void updateState(AppState newState) {
    final next = _normalize == null ? newState : _normalize(newState);
    state = next;
    _repository.save(next);
  }

  /// Menormalkan ulang state sekarang, mis. saat hari berganti.
  void renormalize() {
    final normalize = _normalize;
    if (normalize == null) return;
    final next = normalize(state);
    if (identical(next.activities, state.activities)) return;
    updateState(next);
  }

  /// Reload state from repository.
  Future<void> reload() async {
    final loaded = await _repository.load();
    if (loaded != null) {
      state = loaded;
    }
  }
}

/// State awal yang dimuat di main(); kosong bila belum ada data.
final initialAppStateProvider = Provider<AppState>((ref) => AppState.empty());

/// Provider for AppStateNotifier.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  final repository = ref.watch(repositoryProvider);
  final notifier = AppStateNotifier(
    repository,
    ref.read(initialAppStateProvider),
    normalize: (s) => s.copyWith(
      activities: materializeRecurring(
        s.activities,
        ref.read(clockProvider).now,
      ),
    ),
  );
  // Hari berganti: perluas seri berulang tanpa menunggu perubahan lain.
  ref.listen<DateTime>(currentDayProvider, (_, _) => notifier.renormalize());
  return notifier;
});

/// Provider for the currently active role ('caregiver' or 'child').
final activeRoleProvider = StateProvider<String?>((ref) => null);

/// Provider for the currently selected child ID in caregiver view.
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

/// Anak yang sedang dipakai: anak terpilih, atau anak pertama, atau null.
final currentChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(appStateProvider.select((s) => s.children));
  if (children.isEmpty) return null;
  final selectedId = ref.watch(selectedChildIdProvider);
  if (selectedId != null) {
    for (final child in children) {
      if (child.id == selectedId) return child;
    }
  }
  return children.first;
});
