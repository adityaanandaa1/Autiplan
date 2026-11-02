import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double kartuOrangTuaValue = 16.0;
  static const double kolomIsianValue = 12.0;
  static const double pilValue = 12.0;
  static const double ubinIkon10Value = 10.0;
  static const double sheetAtasValue = 24.0;
  static const double dialogValue = 20.0;
  static const double kartuAnakValue = 20.0;
  static const double barisLangkahAnakValue = 16.0;
  static const double tombolAnakValue = 28.0;
  static const double tombolOrangTuaValue = 12.0;

  static const BorderRadius kartuOrangTua = BorderRadius.all(
    Radius.circular(kartuOrangTuaValue),
  );
  static const BorderRadius kolomIsian = BorderRadius.all(
    Radius.circular(kolomIsianValue),
  );
  static const BorderRadius pil = BorderRadius.all(Radius.circular(pilValue));
  static const BorderRadius ubinIkon10 = BorderRadius.all(
    Radius.circular(ubinIkon10Value),
  );
  static const BorderRadius sheetAtas = BorderRadius.vertical(
    top: Radius.circular(sheetAtasValue),
  );
  static const BorderRadius dialog = BorderRadius.all(
    Radius.circular(dialogValue),
  );
  static const BorderRadius kartuAnak = BorderRadius.all(
    Radius.circular(kartuAnakValue),
  );
  static const BorderRadius barisLangkahAnak = BorderRadius.all(
    Radius.circular(barisLangkahAnakValue),
  );
  static const BorderRadius tombolAnak = BorderRadius.all(
    Radius.circular(tombolAnakValue),
  );
  static const BorderRadius tombolOrangTua = BorderRadius.all(
    Radius.circular(tombolOrangTuaValue),
  );
}
