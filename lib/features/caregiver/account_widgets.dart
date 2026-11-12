import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/card_surface.dart';
import '../../core/widgets/initials.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// Nama anak yang HP-nya terhubung, dipetakan dari `childId` perangkat ke
/// [children]. Beberapa anak digabung dengan koma; null bila tidak ada.
String? linkedChildNamesOf(List<LinkedDevice> devices, List<Child> children) {
  final names = <String>[];
  for (final device in devices) {
    for (final c in children) {
      if (c.id == device.childId && !names.contains(c.name)) names.add(c.name);
    }
  }
  return names.isEmpty ? null : names.join(', ');
}

class AccountProfileCard extends ConsumerWidget {
  const AccountProfileCard({super.key, this.linkedChildName});

  /// Nama anak yang HP-nya sudah terhubung, atau null bila belum.
  final String? linkedChildName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caregiverName = ref.watch(
      appStateProvider.select((s) => s.settings.caregiverName),
    );
    final displayName = caregiverName.isEmpty ? 'Pengasuh' : caregiverName;
    final linkedChildName = this.linkedChildName;

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
            child: Center(
              child: Text(
                initialsOf(caregiverName),
                style: AppTypography.judulBaris,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.grid12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTypography.judulBaris),
                const SizedBox(height: AppSpacing.grid2),
                Text(
                  linkedChildName == null
                      ? 'Pengasuh utama · Belum terhubung ke HP anak'
                      : 'Pengasuh utama · Terhubung ke HP $linkedChildName',
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

class AccountListRow extends StatelessWidget {
  const AccountListRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  /// Menampilkan spinner pengganti panah dan mengabaikan ketukan.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    // Baris tanpa nilai hanya setinggi ubin ikon (40), di bawah batas sentuh.
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: AppRadius.kolomIsian,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
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
            if (loading)
              const SizedBox(
                width: AppSpacing.iconSize20,
                height: AppSpacing.iconSize20,
                child: CircularProgressIndicator(
                  strokeWidth: AppSpacing.grid2,
                  color: AppColors.utama,
                ),
              )
            else
              const Icon(
                LucideIcons.chevronRight,
                size: AppSpacing.iconSize20,
                color: AppColors.teksSekunder,
              ),
          ],
        ),
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
