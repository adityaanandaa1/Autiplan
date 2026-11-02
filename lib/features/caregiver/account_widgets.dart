import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/card_surface.dart';
import '../../data/models/models.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      padding: const EdgeInsets.all(AppSpacing.grid16),
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconTile40,
            height: AppSpacing.iconTile40,
            decoration: const BoxDecoration(
              color: AppColors.utamaLembut,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('IS', style: AppTypography.judulBaris),
            ),
          ),
          const SizedBox(width: AppSpacing.grid12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bu Sari', style: AppTypography.judulBaris),
                SizedBox(height: AppSpacing.grid2),
                Text(
                  'Pengasuh utama · Terhubung ke HP Rafi',
                  style: AppTypography.meta,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountChildRow extends StatelessWidget {
  const AccountChildRow({
    super.key,
    required this.child,
    required this.isLast,
  });

  final Child child;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: AppSpacing.iconTile40,
              height: AppSpacing.iconTile40,
              decoration: const BoxDecoration(
                color: AppColors.anakLembut,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  child.name.substring(0, 1),
                  style: AppTypography.judulBaris,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.grid12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.fullName, style: AppTypography.judulBaris),
                  const SizedBox(height: AppSpacing.grid2),
                  Text(
                    '${child.age} tahun · Tema ${themeName(child.theme)}',
                    style: AppTypography.meta,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: AppSpacing.grid12),
          const AccountListDivider(),
        ],
      ],
    );
  }
}

String themeName(ChildTheme theme) {
  switch (theme) {
    case ChildTheme.lautTenang:
      return 'Laut Tenang';
    case ChildTheme.padangHijau:
      return 'Padang Hijau';
    case ChildTheme.pagiHangat:
      return 'Pagi Hangat';
  }
}

class AccountListRow extends StatelessWidget {
  const AccountListRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.kolomIsian,
      child: Row(
        children: [
          Container(
            width: AppSpacing.iconTile40,
            height: AppSpacing.iconTile40,
            decoration: const BoxDecoration(
              color: AppColors.latar,
              borderRadius: AppRadius.ubinIkon10,
            ),
            child: Icon(
              icon,
              size: AppSpacing.iconSize20,
              color: AppColors.utama,
            ),
          ),
          const SizedBox(width: AppSpacing.grid12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.judulBaris),
                if (value.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.grid2),
                  Text(value, style: AppTypography.meta),
                ],
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: AppSpacing.iconSize20,
            color: AppColors.teksSekunder,
          ),
        ],
      ),
    );
  }
}

class AccountListDivider extends StatelessWidget {
  const AccountListDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.grid12),
      height: AppSpacing.strokeThin,
      color: AppColors.garis,
    );
  }
}
