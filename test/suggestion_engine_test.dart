import 'package:autiplan/core/clock.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/seed.dart';
import 'package:autiplan/domain/suggestion_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Suggestion Engine (Test 9–11)', () {
    late AppState state;
    late DateTime now;

    setUp(() {
      state = buildSeedState();
      now = Clock.demoTime;
    });

    test('Test 9: Independence muncul dari seed', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final suggestions = generateSuggestions(state, now, rafi.id);

      final independence = suggestions.where(
        (s) => s.type == SuggestionType.independence,
      );
      expect(independence.isNotEmpty, isTrue);

      final sepedaSuggestion = independence.singleWhere(
        (s) => s.body.contains('Sepeda Santai'),
      );
      expect(sepedaSuggestion.body, contains('5 hari berturut-turut'));
      expect(sepedaSuggestion.body, contains('3 jadi 1'));
      expect(
        sepedaSuggestion.reasonData,
        'Sepeda Santai selesai tepat waktu 24–30 April minggu ini.',
      );
    });

    test('Test 9: Independence hilang setelah independentMode = true', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final sepeda = state.activities.firstWhere(
        (a) =>
            a.childId == rafi.id &&
            a.title == 'Sepeda Santai' &&
            a.date == DateTime(2026, 5, 1),
      );

      final updatedState = state.copyWith(
        activities: state.activities.map((a) {
          if (a.id == sepeda.id) {
            return a.copyWith(independentMode: true);
          }
          return a;
        }).toList(),
      );

      final suggestions = generateSuggestions(updatedState, now, rafi.id);
      final independence = suggestions.where(
        (s) =>
            s.type == SuggestionType.independence &&
            s.payload['activityId'] == sepeda.id,
      );
      expect(independence, isEmpty);
    });

    test(
      'Test 9: Independence tidak muncul jika satu hari tidak tepat waktu',
      () {
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');

        // Ubah completion 29 April jadi tidak tepat waktu
        final updatedCompletions = state.completions.map((c) {
          if (c.activityId == 'rafi-sepeda-20260429') {
            return c.copyWith(onTime: false);
          }
          return c;
        }).toList();

        final updatedState = state.copyWith(completions: updatedCompletions);
        final suggestions = generateSuggestions(updatedState, now, rafi.id);

        final independence = suggestions.where(
          (s) =>
              s.type == SuggestionType.independence &&
              s.body.contains('Sepeda'),
        );
        expect(independence, isEmpty);
      },
    );

    test('Test 10: QuietTime tidak muncul di seed', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final suggestions = generateSuggestions(state, now, rafi.id);

      final quietTime = suggestions.where(
        (s) => s.type == SuggestionType.quietTime,
      );
      expect(quietTime, isEmpty);
    });

    test(
      'Test 10: QuietTime muncul setelah Les diubah jadi Nonton 20.00–20.45',
      () {
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
        final les = state.activities.firstWhere(
          (a) => a.childId == rafi.id && a.title == 'Les dengan Pak Lana',
        );

        final nonton = les.copyWith(
          title: 'Nonton film bersama',
          shortTitle: 'Nonton',
          icon: ActivityIcon.nonton,
          usesScreen: true,
        );

        final updatedState = state.copyWith(
          activities: state.activities
              .map((a) => a.id == les.id ? nonton : a)
              .toList(),
        );

        final suggestions = generateSuggestions(updatedState, now, rafi.id);
        final quietTime = suggestions.where(
          (s) => s.type == SuggestionType.quietTime,
        );

        expect(quietTime.isNotEmpty, isTrue);
        final suggestion = quietTime.first;
        expect(suggestion.body, contains('Nonton film bersama'));
        expect(suggestion.body, contains('15 menit sebelum tidur'));
      },
    );

    test(
      'Test 11: EmptyDay muncul untuk Sabtu 2 Mei dengan usulan bersepeda',
      () {
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
        final suggestions = generateSuggestions(state, now, rafi.id);

        final emptyDay = suggestions.where(
          (s) => s.type == SuggestionType.emptyDay,
        );
        expect(emptyDay.isNotEmpty, isTrue);

        final saturdaySuggestion = emptyDay.singleWhere(
          (s) => s.id == 'emptyDay:2026-05-02',
        );
        expect(saturdaySuggestion.body, contains('Sabtu masih kosong'));
        expect(saturdaySuggestion.body, contains('Bersepeda pagi'));
        expect(saturdaySuggestion.payload['icon'], 'sepeda');
      },
    );
  });

  group('Perbaikan bug Tahap 2', () {
    test(
      'Bug A: emptyDay hanya sampai Minggu pada minggu yang ditampilkan',
      () {
        final state = buildSeedState();
        final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
        final ids = generateSuggestions(state, Clock.demoTime, rafi.id)
            .where((s) => s.type == SuggestionType.emptyDay)
            .map((s) => s.id)
            .toSet();
        expect(ids, {'emptyDay:2026-05-02', 'emptyDay:2026-05-03'});
      },
    );

    test('Bug B: tanpa kegiatan sama sekali tidak melempar', () {
      final state = buildSeedState();
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final empty = state.copyWith(
        activities: state.activities
            .where((a) => a.childId != rafi.id)
            .toList(),
      );
      expect(
        () => generateSuggestions(empty, Clock.demoTime, rafi.id),
        returnsNormally,
      );
    });
  });
}
