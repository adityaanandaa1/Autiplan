import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static const String fontParent = 'Inter';
  static const String fontChild = 'Lexend';

  // ── Orang Tua (Inter) ───────────────────────────────────────────
  static const TextStyle judulHeader = TextStyle(
    fontFamily: fontParent,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.teks,
  );

  static const TextStyle logo = TextStyle(
    fontFamily: fontParent,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.utama,
  );

  static const TextStyle sapaan = TextStyle(
    fontFamily: fontParent,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.teks,
  );

  static const TextStyle judulSheet = TextStyle(
    fontFamily: fontParent,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.teks,
  );

  static const TextStyle judulKartu = TextStyle(
    fontFamily: fontParent,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.teks,
  );

  static const TextStyle isi = TextStyle(
    fontFamily: fontParent,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.teks,
  );

  static const TextStyle judulBaris = TextStyle(
    fontFamily: fontParent,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.teks,
  );

  static const TextStyle kecil = TextStyle(
    fontFamily: fontParent,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.teks,
  );

  static const TextStyle meta = TextStyle(
    fontFamily: fontParent,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.teksSekunder,
  );

  static const TextStyle mikro = TextStyle(
    fontFamily: fontParent,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.teks,
  );

  // ── Anak (Lexend, line-height 140%) ─────────────────────────────
  static const TextStyle sapaanAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.teks,
  );

  static const TextStyle judulAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.teks,
  );

  static const TextStyle kegiatanAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.teks,
  );

  static const TextStyle isiAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.teks,
  );

  static const TextStyle sekunderAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.teksSekunder,
  );

  static const TextStyle jamAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.teksSekunder,
  );

  static const TextStyle labelAnak = TextStyle(
    fontFamily: fontChild,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.teks,
  );
}
