import 'package:flutter/widgets.dart';

/// Inisial nama untuk avatar: satu kata satu huruf, lebih dari satu kata dua
/// huruf (kata pertama dan terakhir), nama kosong "?".
///
/// Memakai `characters` supaya emoji dan huruf beraksen tidak terpotong.
String initialsOf(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.characters.first.toUpperCase();
  return (words.first.characters.first + words.last.characters.first)
      .toUpperCase();
}
