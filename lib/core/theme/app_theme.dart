import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';
import 'child_palette.dart';

ThemeData buildParentTheme({
  ChildPalette childPalette = ChildPalette.lautTenang,
}) {
  return ThemeData(
    useMaterial3: true,
    fontFamily: AppTypography.fontParent,
    scaffoldBackgroundColor: AppColors.latar,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.utama,
      onPrimary: Colors.white,
      primaryContainer: AppColors.utamaLembut,
      onPrimaryContainer: AppColors.utama,
      secondary: AppColors.anakAksen,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.anakLembut,
      onSecondaryContainer: AppColors.teks,
      surface: AppColors.permukaan,
      onSurface: AppColors.teks,
      error: AppColors.bahaya,
      onError: Colors.white,
      errorContainer: AppColors.bahayaLembut,
      onErrorContainer: AppColors.bahaya,
      outline: AppColors.garis,
    ),
    extensions: [childPalette],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.judulHeader,
      iconTheme: IconThemeData(color: AppColors.teks),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.permukaan,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.kartuOrangTua),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.latar,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: AppRadius.kolomIsian,
        borderSide: BorderSide(color: AppColors.garis),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.kolomIsian,
        borderSide: BorderSide(color: AppColors.garis),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.kolomIsian,
        borderSide: BorderSide(color: AppColors.utama, width: 1.5),
      ),
      hintStyle: TextStyle(
        fontFamily: AppTypography.fontParent,
        fontSize: 15,
        color: AppColors.teksSekunder,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.utama,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.tombolOrangTua,
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontParent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.permukaan,
      elevation: 0,
      selectedItemColor: AppColors.utama,
      unselectedItemColor: AppColors.teksSekunder,
      selectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontParent,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontParent,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.garis,
      thickness: 1,
      space: 1,
    ),
  );
}
