import 'dart:convert';

import 'package:autiplan/data/models/app_state.dart';
import 'package:autiplan/data/repository.dart';
import 'package:autiplan/data/seed.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AutiPlanRepository] implementation backed by [SharedPreferences].
///
/// Stores the entire [AppState] as a single JSON string under [_key].
class LocalRepository implements AutiPlanRepository {
  LocalRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'autiplan_state';

  @override
  Future<AppState?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppState.fromJson(json);
    } catch (_) {
      // Data lokal rusak / skema lama: perlakukan seperti belum ada data
      // supaya pemanggil jatuh ke seed alih-alih crash.
      return null;
    }
  }

  @override
  Future<void> save(AppState state) async {
    final raw = jsonEncode(state.toJson());
    await _prefs.setString(_key, raw);
  }

  @override
  Future<void> reset() async {
    final seed = buildSeedState();
    await save(seed);
  }
}
