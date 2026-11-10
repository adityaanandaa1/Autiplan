import 'package:flutter/material.dart';

abstract final class AppColors {
  // Warna Orang Tua (Caregiver)
  static const Color latar = Color(0xFFF6F7F9);
  static const Color permukaan = Color(0xFFFFFFFF);
  static const Color utama = Color(0xFF3A6EA8);
  static const Color utamaLembut = Color(0xFFE5EDF7);
  static const Color teks = Color(0xFF2F3A45);
  static const Color teksSekunder = Color(0xFF5C6775);
  static const Color garis = Color(0xFFE4E8EC);
  static const Color sukses = Color(0xFF4F8F6A);
  static const Color suksesLembut = Color(0xFFE3F0E8);
  static const Color bahaya = Color(0xFFB5524D);
  static const Color bahayaLembut = Color(0xFFF6E4E3);
  static const Color saranLembut = Color(0xFFFAF3EC);
  static const Color saranTeks = Color(0xFF8A5A3C);
  static const Color anakLembut = Color(0xFFDCEDF0);
  static const Color anakAksen = Color(0xFF6FA3B0);

  // Semantik: teks/ikon di atas isian berwarna (tombol utama, pil, FAB, dll.)
  static const Color teksDiAtasUtama = Color(0xFFFFFFFF);
  static const Color transparan = Color(0x00000000);

  // Opasitas
  static const double alphaNonaktif = 0.4;
  static const double alphaSelesai = 0.6;
  static const double alphaPenuh = 1.0;
  static const double alphaBayangan = 0.25;
}
