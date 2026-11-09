import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:autiplan/domain/schedule_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Completion Logic (Test 12)', () {
    late AppState state;

    setUp(() {
      state = buildFixtureState();
    });

    Activity sepedaHariIni() {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      return state.activities.firstWhere(
        (a) =>
            a.childId == rafi.id &&
            a.title == 'Sepeda Santai' &&
            a.date == DateTime(2026, 5, 1),
      );
    }

    test('Test 12: Tombol selesai nonaktif sampai semua langkah dicentang', () {
      final sepeda = sepedaHariIni();
      expect(sepeda.steps.length, 3);

      expect(canComplete(sepeda, 0), isFalse);
      expect(canComplete(sepeda, 2), isFalse);
      expect(canComplete(sepeda, 3), isTrue);
    });

    test('Test 12: Tombol aktif langsung bila independentMode', () {
      final mandiri = sepedaHariIni().copyWith(independentMode: true);
      expect(canComplete(mandiri, 0), isTrue);
    });

    test('Test 12: Aktivitas tanpa langkah tombol langsung aktif', () {
      final atalia = state.children.firstWhere((c) => c.name == 'Atalia');
      final puzzle = state.activities.firstWhere(
        (a) => a.childId == atalia.id && a.title == 'Bermain Puzzle',
      );
      expect(puzzle.steps, isEmpty);
      expect(canComplete(puzzle, 0), isTrue);
    });
  });
}
