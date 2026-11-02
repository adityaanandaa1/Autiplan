import 'package:autiplan/data/models/child_theme.dart';
import 'package:flutter/material.dart';

class ChildPalette extends ThemeExtension<ChildPalette> {
  const ChildPalette({
    required this.anakLatar,
    required this.anakAksen,
    required this.anakAksenLembut,
    required this.anakAksenKuat,
  });

  final Color anakLatar;
  final Color anakAksen;
  final Color anakAksenLembut;
  final Color anakAksenKuat;

  static const ChildPalette lautTenang = ChildPalette(
    anakLatar: Color(0xFFEEF5F6),
    anakAksen: Color(0xFF6FA3B0),
    anakAksenLembut: Color(0xFFDCEDF0),
    anakAksenKuat: Color(0xFF3F6F7A),
  );

  static const ChildPalette padangHijau = ChildPalette(
    anakLatar: Color(0xFFF1F5EC),
    anakAksen: Color(0xFF89AE78),
    anakAksenLembut: Color(0xFFE1EDD8),
    anakAksenKuat: Color(0xFF4E6E40),
  );

  static const ChildPalette pagiHangat = ChildPalette(
    anakLatar: Color(0xFFFAF3EC),
    anakAksen: Color(0xFFD2A07F),
    anakAksenLembut: Color(0xFFF5E4D7),
    anakAksenKuat: Color(0xFF8A5A3C),
  );

  static ChildPalette fromTheme(ChildTheme theme) {
    switch (theme) {
      case ChildTheme.lautTenang:
        return lautTenang;
      case ChildTheme.padangHijau:
        return padangHijau;
      case ChildTheme.pagiHangat:
        return pagiHangat;
    }
  }

  @override
  ChildPalette copyWith({
    Color? anakLatar,
    Color? anakAksen,
    Color? anakAksenLembut,
    Color? anakAksenKuat,
  }) {
    return ChildPalette(
      anakLatar: anakLatar ?? this.anakLatar,
      anakAksen: anakAksen ?? this.anakAksen,
      anakAksenLembut: anakAksenLembut ?? this.anakAksenLembut,
      anakAksenKuat: anakAksenKuat ?? this.anakAksenKuat,
    );
  }

  @override
  ThemeExtension<ChildPalette> lerp(
    covariant ThemeExtension<ChildPalette>? other,
    double t,
  ) {
    if (other is! ChildPalette) {
      return this;
    }
    return ChildPalette(
      anakLatar: Color.lerp(anakLatar, other.anakLatar, t)!,
      anakAksen: Color.lerp(anakAksen, other.anakAksen, t)!,
      anakAksenLembut: Color.lerp(anakAksenLembut, other.anakAksenLembut, t)!,
      anakAksenKuat: Color.lerp(anakAksenKuat, other.anakAksenKuat, t)!,
    );
  }
}
