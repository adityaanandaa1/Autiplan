import 'package:autiplan/data/models/app_state.dart';

/// Interface for reading and writing the entire application state.
///
/// The repository manages a single [AppState] object.
/// Implementations can use any storage mechanism.
abstract class AutiPlanRepository {
  /// Load the full application state.
  /// Returns `null` if no state has been saved yet.
  Future<AppState?> load();

  /// Save the full application state.
  Future<void> save(AppState state);
}
