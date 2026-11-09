import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';

/// `/mulai`: sambutan awal. Kartu "Orang tua" masuk lewat email, kartu "Anak"
/// mengarah ke `/hubungkan` (layar penghubung dibuat di Tahap 11).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingParent,
                vertical: AppSpacing.grid24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Text(
                    'AutiPlan',
                    textAlign: TextAlign.center,
                    style: AppTypography.logo,
                  ),
                  const SizedBox(height: AppSpacing.grid8),
                  const Text(
                    'HP ini dipakai oleh siapa?',
                    textAlign: TextAlign.center,
                    style: AppTypography.isi,
                  ),
                  const SizedBox(height: AppSpacing.grid40),
                  _WelcomeCard(
                    title: 'Orang tua',
                    subtitle: 'Atur jadwal, beri tahu perubahan, terima saran',
                    icon: LucideIcons.user,
                    onTap: () => context.go('/masuk'),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  _WelcomeCard(
                    title: 'Anak',
                    subtitle: 'Lihat jadwal hari ini dan ikuti kegiatan',
                    icon: LucideIcons.smile,
                    onTap: () => context.go('/hubungkan'),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.permukaan,
      borderRadius: AppRadius.kartuOrangTua,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.kartuOrangTua,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.grid20),
          decoration: BoxDecoration(
            borderRadius: AppRadius.kartuOrangTua,
            border: Border.all(color: AppColors.garis),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.iconTileLarge,
                height: AppSpacing.iconTileLarge,
                decoration: const BoxDecoration(
                  color: AppColors.utamaLembut,
                  borderRadius: AppRadius.ubinIkon10,
                ),
                child: Icon(
                  icon,
                  color: AppColors.utama,
                  size: AppSpacing.iconSize24,
                ),
              ),
              const SizedBox(width: AppSpacing.grid16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.judulKartu),
                    const SizedBox(height: AppSpacing.grid4),
                    Text(subtitle, style: AppTypography.meta),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: AppColors.teksSekunder,
                size: AppSpacing.iconSize20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
