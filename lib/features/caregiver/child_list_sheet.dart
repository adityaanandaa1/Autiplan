import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/calm_snackbar.dart';
import '../../core/widgets/initials.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import 'account_sheets.dart';

/// Sheet "Daftar anak": setiap anak punya aksi ubah dan hapus.
void showChildListSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => const _ChildListSheet(),
  );
}

class _ChildListSheet extends ConsumerWidget {
  const _ChildListSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(appStateProvider.select((s) => s.children));
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.sheetAtas,
      ),
      padding: const EdgeInsets.all(AppSpacing.grid20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Daftar anak', style: AppTypography.judulSheet),
            const SizedBox(height: AppSpacing.grid16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final child in children)
                    _ChildRow(child: child, canDelete: children.length > 1),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.grid16),
            SecondaryButton(
              label: 'Tutup',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildRow extends ConsumerWidget {
  const _ChildRow({required this.child, required this.canDelete});

  final Child child;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid4),
      child: Row(
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
                initialsOf(child.name),
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
                Text('${child.age} tahun', style: AppTypography.meta),
                Wrap(
                  spacing: AppSpacing.grid8,
                  children: [
                    _ProfileButton(
                      icon: LucideIcons.heart,
                      label: 'Suka (${child.likes.length})',
                      onPressed: () =>
                          showProfileListSheet(context, ref, child, 'Suka'),
                    ),
                    _ProfileButton(
                      icon: LucideIcons.sun,
                      label: 'Hindari (${child.avoids.length})',
                      onPressed: () =>
                          showProfileListSheet(context, ref, child, 'Hindari'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah ${child.name}',
            onPressed: () => showChildFormSheet(context, ref, existing: child),
            icon: const Icon(
              LucideIcons.pencil,
              size: AppSpacing.iconSize20,
              color: AppColors.utama,
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Hapus ${child.name}',
              onPressed: () => _confirmDelete(context, ref, child),
              icon: const Icon(
                LucideIcons.trash2,
                size: AppSpacing.iconSize20,
                color: AppColors.bahaya,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.utama,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.grid8),
      ),
      icon: Icon(icon, size: AppSpacing.iconSize16),
      label: Text(label, style: AppTypography.kecil),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Child child,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      contentPadding: const EdgeInsets.all(AppSpacing.grid20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Hapus ${child.name}?', style: AppTypography.judulSheet),
          const SizedBox(height: AppSpacing.grid8),
          Text(
            'Semua jadwal ${child.name} ikut terhapus dan HP ${child.name} diputuskan.',
            textAlign: TextAlign.center,
            style: AppTypography.kecil.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.grid24),
          DangerButton(
            label: 'Hapus',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: AppSpacing.grid8),
          SecondaryButton(
            label: 'Batal',
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true) return;

  final state = ref.read(appStateProvider);
  final activityIds = {
    for (final a in state.activities)
      if (a.childId == child.id) a.id,
  };
  ref
      .read(appStateProvider.notifier)
      .updateState(
        state.copyWith(
          children: [
            for (final c in state.children)
              if (c.id != child.id) c,
          ],
          activities: [
            for (final a in state.activities)
              if (a.childId != child.id) a,
          ],
          completions: [
            for (final c in state.completions)
              if (!activityIds.contains(c.activityId)) c,
          ],
          notices: [
            for (final n in state.notices)
              if (n.childId != child.id) n,
          ],
        ),
      );
  if (ref.read(selectedChildIdProvider) == child.id) {
    ref.read(selectedChildIdProvider.notifier).state = null;
  }
  try {
    await ref.read(repositoryProvider).unlinkChildDevice(child.id);
  } on Object {
    // HP anak tetap terputus sendiri saat dokumen anak hilang.
  }
  if (context.mounted) {
    CalmSnackbar.show(context, message: '${child.name} sudah dihapus');
  }
}
