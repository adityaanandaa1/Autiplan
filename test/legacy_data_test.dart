import 'dart:convert';

import 'package:autiplan/data/local_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixture_state.dart';

void main() {
  const key = 'autiplan_state';
  const backupKey = 'autiplan_state_unreadable';

  Future<SharedPreferences> prefsWith(String raw) async {
    SharedPreferences.setMockInitialValues({key: raw});
    return SharedPreferences.getInstance();
  }

  test('data contoh versi lama dibuang', () async {
    final json = buildFixtureState().toJson();
    (json['settings'] as Map<String, dynamic>)['demoClockEnabled'] = true;
    final prefs = await prefsWith(jsonEncode(json));

    expect(await LocalRepository(prefs).load(), isNull);
    expect(prefs.getString(key), isNull);
  });

  test('data versi sekarang tetap terbaca', () async {
    final state = buildFixtureState();
    final prefs = await prefsWith(jsonEncode(state.toJson()));

    expect(await LocalRepository(prefs).load(), state);
  });

  test('data yang tidak terbaca disalin sebelum bisa tertimpa', () async {
    const raw = '{rusak';
    final prefs = await prefsWith(raw);

    expect(await LocalRepository(prefs).load(), isNull);
    expect(prefs.getString(backupKey), raw);
  });
}
