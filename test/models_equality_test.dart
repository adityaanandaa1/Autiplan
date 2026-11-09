import 'package:autiplan/data/models/models.dart';
import 'support/fixture_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final seed = buildFixtureState();

  group('Activity ==', () {
    final a = seed.activities.first;
    test('salinan identik sama dan hash sama', () {
      final b = a.copyWith();
      expect(b, a);
      expect(b.hashCode, a.hashCode);
    });
    test('steps berbeda -> tidak sama', () {
      expect(a.copyWith(steps: const ['x']), isNot(a));
    });
    test('repeatWeekdays berbeda -> tidak sama', () {
      expect(a.copyWith(repeatWeekdays: const {6}), isNot(a));
    });
  });

  group('Child ==', () {
    final c = seed.children.first;
    test('salinan identik sama dan hash sama', () {
      final d = c.copyWith();
      expect(d, c);
      expect(d.hashCode, c.hashCode);
    });
    test('likes berbeda -> tidak sama', () {
      expect(c.copyWith(likes: const ['Lain']), isNot(c));
    });
    test('avoids berbeda -> tidak sama', () {
      expect(c.copyWith(avoids: const ['Lain']), isNot(c));
    });
  });

  group('Completion ==', () {
    final c = seed.completions.first;
    test('salinan identik sama dan hash sama', () {
      final d = c.copyWith();
      expect(d, c);
      expect(d.hashCode, c.hashCode);
    });
    test('stepsChecked berbeda -> tidak sama', () {
      expect(c.copyWith(stepsChecked: const [false]), isNot(c));
    });
  });

  group('Suggestion ==', () {
    const s = Suggestion(
      id: 'independence:a',
      type: SuggestionType.independence,
      childId: 'child-rafi',
      title: 't',
      body: 'b',
      reasonData: 'rd',
      reasonBasis: 'rb',
      actionLabel: 'al',
      payload: {'k': 1},
      status: SuggestionStatus.active,
    );
    test('salinan identik sama dan hash sama', () {
      final t = s.copyWith();
      expect(t, s);
      expect(t.hashCode, s.hashCode);
    });
    test('tiap field berbeda -> tidak sama', () {
      expect(s.copyWith(body: 'x'), isNot(s));
      expect(s.copyWith(reasonData: 'x'), isNot(s));
      expect(s.copyWith(reasonBasis: 'x'), isNot(s));
      expect(s.copyWith(actionLabel: 'x'), isNot(s));
      expect(s.copyWith(payload: const {'k': 2}), isNot(s));
      expect(s.copyWith(payload: const {}), isNot(s));
    });
  });

  group('AppState ==', () {
    test('salinan identik sama dan hash sama', () {
      final other = buildFixtureState();
      expect(other, seed);
      expect(other.hashCode, seed.hashCode);
    });
    test('perubahan kecil -> tidak sama', () {
      final changed = seed.copyWith(
        activities: [
          seed.activities.first.copyWith(steps: const ['x']),
          ...seed.activities.skip(1),
        ],
      );
      expect(changed, isNot(seed));
      expect(
        seed.copyWith(
          suggestionStatus: const {'a': SuggestionStatus.dismissed},
        ),
        isNot(seed),
      );
    });
  });
}
