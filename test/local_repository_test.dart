import 'dart:convert';

import 'package:autiplan/data/local_repository.dart';
import 'support/fixture_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<LocalRepository> _repoWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalRepository(await SharedPreferences.getInstance());
}

void main() {
  group('LocalRepository.load', () {
    test('kunci kosong -> null', () async {
      final repo = await _repoWith({});
      expect(await repo.load(), isNull);
    });

    test('bukan JSON -> null, tidak crash', () async {
      final repo = await _repoWith({'autiplan_state': 'bukan json {{'});
      expect(await repo.load(), isNull);
    });

    test('JSON tidak lengkap -> null, tidak crash', () async {
      final repo = await _repoWith({
        'autiplan_state': '{"children":[],"activities":[],"completions":[]}',
      });
      expect(await repo.load(), isNull);
    });

    test('state valid -> kembali identik', () async {
      final seed = buildFixtureState();
      final repo = await _repoWith({
        'autiplan_state': jsonEncode(seed.toJson()),
      });
      expect(await repo.load(), seed);
    });

    test('save lalu load -> identik', () async {
      final repo = await _repoWith({});
      final seed = buildFixtureState();
      await repo.save(seed);
      expect(await repo.load(), seed);
    });
  });
}
