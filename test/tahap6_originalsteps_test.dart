// Tes untuk prasyarat Tahap 6: originalSteps field di Activity untuk
// mendukung "Bisa dikembalikan ke N langkah" (HANDOFF §9.3).
import 'package:autiplan/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Activity.originalSteps', () {
    test('serialisasi roundtrip dengan originalSteps', () {
      final activity = Activity(
        id: 'a1',
        childId: 'c1',
        title: 'Sepeda',
        shortTitle: 'Sepeda',
        icon: ActivityIcon.sepeda,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(16, 0),
        end: const TimeOfDayLite(17, 0),
        steps: const ['Langkah singkat'],
        independentMode: true,
        originalSteps: const ['Langkah 1', 'Langkah 2', 'Langkah 3'],
      );

      final json = activity.toJson();
      expect(json['originalSteps'], ['Langkah 1', 'Langkah 2', 'Langkah 3']);

      final restored = Activity.fromJson(json);
      expect(restored.originalSteps, activity.originalSteps);
      expect(restored, activity);
    });

    test('serialisasi tanpa originalSteps (null)', () {
      final activity = Activity(
        id: 'a2',
        childId: 'c1',
        title: 'Ngaji',
        shortTitle: 'Ngaji',
        icon: ActivityIcon.ngaji,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(18, 0),
        end: const TimeOfDayLite(19, 0),
        steps: const ['A', 'B'],
        independentMode: false,
      );

      final json = activity.toJson();
      expect(json.containsKey('originalSteps'), false);

      final restored = Activity.fromJson(json);
      expect(restored.originalSteps, null);
      expect(restored, activity);
    });

    test('copyWith dapat mengatur originalSteps', () {
      final base = Activity(
        id: 'a3',
        childId: 'c1',
        title: 'Les',
        shortTitle: 'Les',
        icon: ActivityIcon.les,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(20, 0),
        end: const TimeOfDayLite(20, 45),
        steps: const ['Belajar'],
      );

      final withOriginal = base.copyWith(
        originalSteps: const ['Siapkan buku', 'Belajar', 'Rapikan'],
      );
      expect(withOriginal.originalSteps, ['Siapkan buku', 'Belajar', 'Rapikan']);
      expect(withOriginal.steps, ['Belajar']);
    });

    test('copyWith clearOriginalSteps menghapus field', () {
      final activity = Activity(
        id: 'a4',
        childId: 'c1',
        title: 'Makan',
        shortTitle: 'Makan',
        icon: ActivityIcon.makan,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(12, 0),
        originalSteps: const ['A', 'B', 'C'],
      );

      final cleared = activity.copyWith(clearOriginalSteps: true);
      expect(cleared.originalSteps, null);
    });

    test('equality memperhitungkan originalSteps', () {
      final a1 = Activity(
        id: 'a5',
        childId: 'c1',
        title: 'T',
        shortTitle: 'T',
        icon: ActivityIcon.sepeda,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(10, 0),
        originalSteps: const ['X', 'Y'],
      );

      final a2 = Activity(
        id: 'a5',
        childId: 'c1',
        title: 'T',
        shortTitle: 'T',
        icon: ActivityIcon.sepeda,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(10, 0),
        originalSteps: const ['X', 'Y'],
      );

      final a3 = Activity(
        id: 'a5',
        childId: 'c1',
        title: 'T',
        shortTitle: 'T',
        icon: ActivityIcon.sepeda,
        date: DateTime(2026, 5, 1),
        start: const TimeOfDayLite(10, 0),
        originalSteps: const ['X', 'Z'], // berbeda
      );

      expect(a1, a2);
      expect(a1 == a3, false);
    });
  });
}
