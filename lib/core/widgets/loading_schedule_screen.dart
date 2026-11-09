import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Layar sementara selama jadwal pertama dimuat.
///
/// Teks statis, tanpa animasi: sisi anak tidak boleh melihat jadwal kosong
/// sesaat, dan tidak boleh ada spinner berputar.
class LoadingScheduleScreen extends StatelessWidget {
  const LoadingScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Center(
          child: Semantics(
            label: 'Memuat jadwal',
            child: Text(
              'Memuat jadwal',
              textAlign: TextAlign.center,
              style: AppTypography.isi.copyWith(color: AppColors.teksSekunder),
            ),
          ),
        ),
      ),
    );
  }
}
