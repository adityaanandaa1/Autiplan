import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/activity_icon.dart';

String activityIconLabel(ActivityIcon icon) {
  switch (icon) {
    case ActivityIcon.sekolah:
      return 'Sekolah';
    case ActivityIcon.les:
      return 'Les';
    case ActivityIcon.ngaji:
      return 'Ngaji';
    case ActivityIcon.mandi:
      return 'Mandi';
    case ActivityIcon.makan:
      return 'Makan';
    case ActivityIcon.tidur:
      return 'Tidur';
    case ActivityIcon.main:
      return 'Main';
    case ActivityIcon.sepeda:
      return 'Sepeda';
    case ActivityIcon.nonton:
      return 'Nonton';
  }
}

IconData lucideIconFor(ActivityIcon icon) {
  switch (icon) {
    case ActivityIcon.sekolah:
      return LucideIcons.school;
    case ActivityIcon.les:
      return LucideIcons.bookOpen;
    case ActivityIcon.ngaji:
      return LucideIcons.book;
    case ActivityIcon.mandi:
      return LucideIcons.bath;
    case ActivityIcon.makan:
      return LucideIcons.utensils;
    case ActivityIcon.tidur:
      return LucideIcons.moon;
    case ActivityIcon.main:
      return LucideIcons.gamepad2;
    case ActivityIcon.sepeda:
      return LucideIcons.bike;
    case ActivityIcon.nonton:
      return LucideIcons.tv;
  }
}
