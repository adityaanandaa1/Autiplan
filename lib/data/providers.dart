import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  AppStateNotifier(this._repository, AppState initial) : super(initial);

  final AutiPlanRepository _repository;

  /// Update the state and persist to repository asynchronously.
  void updateState(AppState newState) {
    state = newState;
    _repository.save(newState);
  }

  /// Reload state from repository.
  Future<void> reload() async {
    final loaded = await _repository.load();
    if (loaded != null) {
      state = loaded;
    }
  }
}

/// Provider for AppStateNotifier.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  final repository = ref.watch(repositoryProvider);
  // Start empty; main() overrides this with the loaded state.
  return AppStateNotifier(repository, AppState.empty());
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
