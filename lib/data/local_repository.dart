import 'dart:convert';

import 'package:autiplan/data/models/app_state.dart';
import 'package:autiplan/data/repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [AutiPlanRepository] implementation backed by [SharedPreferences].
///
/// Stores the entire [AppState] as a single JSON string under [_key].
class LocalRepository implements AutiPlanRepository {
  LocalRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'autiplan_state';
  static const String _unreadableBackupKey = 'autiplan_state_unreadable';

  // Hanya versi lama yang menyimpan field ini, dan isinya selalu data contoh.
  static const String _legacySampleDataMarker = 'demoClockEnabled';

  @override
  Future<AppState?> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (_isLegacySampleData(json)) {
        await _prefs.remove(_key);
        return null;
      }
      return AppState.fromJson(json);
    } catch (e) {
      // Simpan salinannya, karena simpanan berikutnya menimpa data ini.
      debugPrint('Data tersimpan tidak terbaca: $e');
      await _prefs.setString(_unreadableBackupKey, raw);
      return null;
    }
  }

  bool _isLegacySampleData(Map<String, dynamic> json) {
    final settings = json['settings'];
    return settings is Map<String, dynamic> &&
        settings.containsKey(_legacySampleDataMarker);
  }

  @override
  Future<void> save(AppState state) async {
    final raw = jsonEncode(state.toJson());
    await _prefs.setString(_key, raw);
  }
}
