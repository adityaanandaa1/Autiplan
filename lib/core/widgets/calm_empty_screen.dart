import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Layar kosong yang tenang saat belum ada anak (akun baru).
///
/// Tidak ada tombol tambah di sisi anak; teksnya netral dan tanpa warna merah.
class CalmEmptyScreen extends StatelessWidget {
  const CalmEmptyScreen({super.key, this.isChild = false});

  final bool isChild;

  @override
  Widget build(BuildContext context) {
    final palette =
        Theme.of(context).extension<ChildPalette>() ?? ChildPalette.lautTenang;
    final background = isChild ? palette.anakLatar : AppColors.latar;
    final style = isChild ? AppTypography.isiAnak : AppTypography.isi;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingParent),
            child: Text(
              'Belum ada jadwal.',
              textAlign: TextAlign.center,
              style: style.copyWith(color: AppColors.teksSekunder),
            ),
          ),
        ),
      ),
    );
  }
}
