import 'package:flutter_test/flutter_test.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/domain/routine_templates.dart';

void main() {
  group('Routine Templates', () {
    test('memiliki minimal 20 opsi template terstruktur', () {
      expect(allRoutineTemplates.length, greaterThanOrEqualTo(20));
      expect(allRoutineTemplates.length, equals(23));
    });

    test('memiliki 4 kategori lengkap: pagi, sekolah, sore, malam', () {
      final categories = allRoutineTemplates.map((t) => t.category).toSet();
      expect(categories, contains(RoutineCategory.pagi));
      expect(categories, contains(RoutineCategory.sekolah));
      expect(categories, contains(RoutineCategory.sore));
      expect(categories, contains(RoutineCategory.malam));
    });

    test('kategori malam memuat opsi ibadah spiritual', () {
      final malamItems = allRoutineTemplates
          .where((t) => t.category == RoutineCategory.malam)
          .toList();
      expect(malamItems.length, greaterThanOrEqualTo(6));

      // Ibadah spiritual
      final spiritualItems = malamItems
          .where((t) => t.icon == ActivityIcon.ngaji)
          .toList();
      expect(spiritualItems.length, greaterThanOrEqualTo(3));
    });

    test('generateActivitiesFromTemplate mengonversi template ke Activity valid', () {
      final date = DateTime(2026, 5, 1);
      final activities = generateActivitiesFromTemplate(
        items: allRoutineTemplates.take(3).toList(),
        childId: 'c1',
        date: date,
      );

      expect(activities.length, equals(3));
      for (final a in activities) {
        expect(a.childId, equals('c1'));
        expect(a.date.year, equals(2026));
        expect(a.date.month, equals(5));
        expect(a.date.day, equals(1));
        expect(a.title.isNotEmpty, isTrue);
        expect(a.steps.isNotEmpty, isTrue);
      }
    });

    test('paket rutinitas (routinePacks) terisi dengan benar', () {
      expect(routinePacks.length, greaterThanOrEqualTo(4));
      for (final pack in routinePacks) {
        expect(pack.items.isNotEmpty, isTrue);
        expect(pack.name.isNotEmpty, isTrue);
      }
    });
  });
}
