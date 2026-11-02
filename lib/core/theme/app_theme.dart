import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
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
      onPrimary: AppColors.teksDiAtasUtama,
      primaryContainer: AppColors.utamaLembut,
      onPrimaryContainer: AppColors.utama,
      secondary: AppColors.anakAksen,
      onSecondary: AppColors.teksDiAtasUtama,
      secondaryContainer: AppColors.anakLembut,
      onSecondaryContainer: AppColors.teks,
      surface: AppColors.permukaan,
      onSurface: AppColors.teks,
      error: AppColors.bahaya,
      onError: AppColors.teksDiAtasUtama,
      errorContainer: AppColors.bahayaLembut,
      onErrorContainer: AppColors.bahaya,
      outline: AppColors.garis,
    ),
    extensions: [childPalette],
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.transparan,
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
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.grid14,
        vertical: AppSpacing.grid13,
      ),
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
        borderSide: BorderSide(
          color: AppColors.utama,
          width: AppSpacing.strokeFocus,
        ),
      ),
      hintStyle: AppTypography.isiHint,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.utama,
        foregroundColor: AppColors.teksDiAtasUtama,
        minimumSize: const Size(double.infinity, AppSpacing.buttonHeightParent),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.tombolOrangTua,
        ),
        textStyle: AppTypography.tombol,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.permukaan,
      elevation: 0,
      selectedItemColor: AppColors.utama,
      unselectedItemColor: AppColors.teksSekunder,
      selectedLabelStyle: AppTypography.labelTabAktif,
      unselectedLabelStyle: AppTypography.labelTab,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.garis,
      thickness: AppSpacing.strokeThin,
      space: AppSpacing.strokeThin,
    ),
  );
}
