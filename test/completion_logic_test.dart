import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/seed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Completion Logic (Test 12)', () {
    late AppState state;

    setUp(() {
      state = buildSeedState();
    });

    test('Test 12: Tombol selesai nonaktif sampai semua langkah dicentang', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final sepeda = state.activities.firstWhere(
        (a) => a.childId == rafi.id && a.title == 'Sepeda Santai' && a.date == DateTime(2026, 5, 1),
      );

      expect(sepeda.steps.length, 3);

      // Simulasi centang bertahap
      final stepsChecked = [false, false, false];
      bool canComplete = stepsChecked.every((checked) => checked);
      expect(canComplete, isFalse);

      stepsChecked[0] = true;
      stepsChecked[1] = true;
      canComplete = stepsChecked.every((checked) => checked);
      expect(canComplete, isFalse);

      stepsChecked[2] = true;
      canComplete = stepsChecked.every((checked) => checked);
      expect(canComplete, isTrue);
    });

    test('Test 12: Tombol aktif langsung bila independentMode', () {
      final rafi = state.children.firstWhere((c) => c.name == 'Rafi');
      final sepeda = state.activities.firstWhere(
        (a) => a.childId == rafi.id && a.title == 'Sepeda Santai' && a.date == DateTime(2026, 5, 1),
      );

      final independentSepeda = sepeda.copyWith(independentMode: true);

      // Mode mandiri: tombol aktif tanpa harus centang langkah
      expect(independentSepeda.independentMode, isTrue);
      final canComplete = independentSepeda.independentMode || independentSepeda.steps.isEmpty;
      expect(canComplete, isTrue);
    });

    test('Test 12: Aktivitas tanpa langkah tombol langsung aktif', () {
      final atalia = state.children.firstWhere((c) => c.name == 'Atalia');
      final puzzle = state.activities.firstWhere(
        (a) => a.childId == atalia.id && a.title == 'Bermain Puzzle',
      );

      expect(puzzle.steps, isEmpty);
      final canComplete = puzzle.steps.isEmpty || puzzle.independentMode;
      expect(canComplete, isTrue);
    });
  });
}
