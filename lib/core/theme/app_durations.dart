import 'package:flutter/material.dart';

abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);

  static const Curve curve = Curves.easeOut;
}
