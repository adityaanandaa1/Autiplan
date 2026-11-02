import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../data/providers.dart';

class RolePickerScreen extends ConsumerWidget {
  const RolePickerScreen({super.key});

  static const String _lastRoleKey = 'last_selected_role';

  Future<void> _selectRole(
    BuildContext context,
    WidgetRef ref,
    String role,
    String route,
  ) async {
    ref.read(activeRoleProvider.notifier).state = role;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_lastRoleKey, role);
    if (context.mounted) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  Text(
                    'AutiPlan',
                    textAlign: TextAlign.center,
                    style: AppTypography.logo,
                  ),
                  const SizedBox(height: AppSpacing.grid8),
                  Text(
                    'Pilih peran untuk demo',
                    textAlign: TextAlign.center,
                    style: AppTypography.isi.copyWith(
                      color: AppColors.teksSekunder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.grid40),
                  _RoleCard(
                    title: 'Orang tua · Bu Sari',
                    subtitle: 'Atur jadwal, beri tahu perubahan, terima saran',
                    icon: LucideIcons.user,
                    onTap: () =>
                        _selectRole(context, ref, 'caregiver', '/ortu/beranda'),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  _RoleCard(
                    title: 'Anak · Rafi',
                    subtitle: 'Lihat jadwal hari ini dan ikuti kegiatan',
                    icon: LucideIcons.smile,
                    onTap: () => _selectRole(context, ref, 'child', '/anak'),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
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
