import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_repository.dart';
import 'models/models.dart';
import 'repository.dart';
import 'seed.dart';

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

  /// Reset the state back to seed data.
  Future<void> resetToSeed() async {
    final seed = buildSeedState();
    state = seed;
    await _repository.save(seed);
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
  // Default to seed if repository load has not happened yet
  return AppStateNotifier(repository, buildSeedState());
});

/// Provider for the currently active role in demo ('caregiver' or 'child').
final activeRoleProvider = StateProvider<String?>((ref) => null);

/// Provider for the currently selected child ID in caregiver view (defaults to Rafi).
final selectedChildIdProvider = StateProvider<String>((ref) => 'child-rafi');
