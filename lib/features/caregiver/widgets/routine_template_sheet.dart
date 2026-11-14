import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/calm_snackbar.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import '../../../domain/routine_templates.dart';
import '../forms/sheet_scaffold.dart';

/// Membuka sheet pemilih template rutinitas siap pakai untuk [child] pada [date].
void showRoutineTemplateSheet(
  BuildContext context,
  WidgetRef ref, {
  required Child child,
  required DateTime date,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RoutineTemplateSheet(child: child, targetDate: date),
  );
}

class _RoutineTemplateSheet extends ConsumerStatefulWidget {
  const _RoutineTemplateSheet({
    required this.child,
    required this.targetDate,
  });

  final Child child;
  final DateTime targetDate;

  @override
  ConsumerState<_RoutineTemplateSheet> createState() =>
      _RoutineTemplateSheetState();
}

class _RoutineTemplateSheetState extends ConsumerState<_RoutineTemplateSheet> {
  int _selectedTabIndex = 0; // 0 = Paket Rutinitas, 1 = Pilihan Kegiatan (23)
  RoutineCategory? _selectedCategory; // null = Semua

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Template Rutinitas',
      subtitle:
          'Pilih rutinitas siap pakai untuk jadwal ${widget.child.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTabSelector(),
          const SizedBox(height: AppSpacing.grid16),
          if (_selectedTabIndex == 0)
            _buildPacksList()
          else ...[
            _buildCategoryFilterChips(),
            const SizedBox(height: AppSpacing.grid12),
            _buildIndividualList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.latar,
        borderRadius: AppRadius.segmen,
      ),
      padding: const EdgeInsets.all(AppSpacing.grid4),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Paket Lengkap (${routinePacks.length})',
              icon: LucideIcons.layers,
              isSelected: _selectedTabIndex == 0,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Pilihan Kegiatan (${allRoutineTemplates.length})',
              icon: LucideIcons.listTodo,
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Semua (${allRoutineTemplates.length})',
            isSelected: _selectedCategory == null,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          for (final cat in RoutineCategory.values) ...[
            const SizedBox(width: AppSpacing.grid8),
            _FilterChip(
              label: '${cat.label} (${allRoutineTemplates.where((t) => t.category == cat).length})',
              isSelected: _selectedCategory == cat,
              onTap: () => setState(() => _selectedCategory = cat),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPacksList() {
    return Column(
      children: [
        for (final pack in routinePacks) ...[
          _RoutinePackCard(
            pack: pack,
            onApply: () => _applyPack(pack),
          ),
          const SizedBox(height: AppSpacing.grid12),
        ],
      ],
    );
  }

  Widget _buildIndividualList() {
    final filtered = _selectedCategory == null
        ? allRoutineTemplates
        : allRoutineTemplates
            .where((t) => t.category == _selectedCategory)
            .toList();

    return Column(
      children: [
        for (final item in filtered) ...[
          _RoutineItemCard(
            item: item,
            onApply: () => _applySingleItem(item),
          ),
          const SizedBox(height: AppSpacing.grid12),
        ],
      ],
    );
  }

  void _applyPack(RoutinePack pack) {
    final state = ref.read(appStateProvider);
    final newActivities = generateActivitiesFromTemplate(
      items: pack.items,
      childId: widget.child.id,
      date: widget.targetDate,
    );

    final updated = List<Activity>.from(state.activities)..addAll(newActivities);
    ref.read(appStateProvider.notifier).updateState(
      state.copyWith(activities: updated),
    );

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message:
          '${pack.name} (${pack.items.length} kegiatan) berhasil ditambahkan.',
    );
  }

  void _applySingleItem(RoutineTemplateItem item) {
    final state = ref.read(appStateProvider);
    final newActivity = item.toActivity(
      childId: widget.child.id,
      date: widget.targetDate,
    );

    final updated = List<Activity>.from(state.activities)..add(newActivity);
    ref.read(appStateProvider.notifier).updateState(
      state.copyWith(activities: updated),
    );

    Navigator.of(context).pop();
    CalmSnackbar.show(
      context,
      message: '"${item.title}" berhasil ditambahkan ke jadwal.',
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.segmenTerpilih,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.permukaan : Colors.transparent,
          borderRadius: AppRadius.segmenTerpilih,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.teks.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppSpacing.iconSize16,
              color: isSelected ? AppColors.utama : AppColors.teksSekunder,
            ),
            const SizedBox(width: AppSpacing.grid6),
            Flexible(
              child: Text(
                label,
                style: AppTypography.meta.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.utama : AppColors.teksSekunder,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pil,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.grid12,
          vertical: AppSpacing.grid8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.utama : AppColors.latar,
          borderRadius: AppRadius.pil,
          border: Border.all(
            color: isSelected ? AppColors.utama : AppColors.garis,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.meta.copyWith(
            color: isSelected
                ? AppColors.teksDiAtasUtama
                : AppColors.teksSekunder,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RoutinePackCard extends StatelessWidget {
  const _RoutinePackCard({
    required this.pack,
    required this.onApply,
  });

  final RoutinePack pack;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.kartuOrangTua,
        border: Border.all(color: AppColors.garis),
      ),
      padding: const EdgeInsets.all(AppSpacing.grid16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.iconTile44,
                height: AppSpacing.iconTile44,
                decoration: const BoxDecoration(
                  color: AppColors.utamaLembut,
                  borderRadius: AppRadius.ubinIkon10,
                ),
                child: Icon(
                  lucideIconFor(pack.icon),
                  size: AppSpacing.iconSize22,
                  color: AppColors.utama,
                ),
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.name, style: AppTypography.judulBaris),
                    const SizedBox(height: AppSpacing.grid2),
                    Text(
                      '${pack.items.length} kegiatan sekaligus',
                      style: AppTypography.meta.copyWith(
                        color: AppColors.utama,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid8),
          Text(
            pack.description,
            style: AppTypography.meta.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.grid12),
          Container(
            padding: const EdgeInsets.all(AppSpacing.grid10),
            decoration: const BoxDecoration(
              color: AppColors.latar,
              borderRadius: AppRadius.kolomIsian,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in pack.items) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.grid2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          item.start.toString(),
                          style: AppTypography.meta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.teks,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.grid8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.meta.copyWith(
                              color: AppColors.teks,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.grid12),
          PrimaryButton(
            label: 'Terapkan Paket (${pack.items.length} Kegiatan)',
            onPressed: onApply,
          ),
        ],
      ),
    );
  }
}

class _RoutineItemCard extends StatelessWidget {
  const _RoutineItemCard({
    required this.item,
    required this.onApply,
  });

  final RoutineTemplateItem item;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final timeStr = item.end != null
        ? '${item.start} – ${item.end}'
        : '${item.start} (Selesai)';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.kartuOrangTua,
        border: Border.all(color: AppColors.garis),
      ),
      padding: const EdgeInsets.all(AppSpacing.grid14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.iconTile40,
                height: AppSpacing.iconTile40,
                decoration: const BoxDecoration(
                  color: AppColors.utamaLembut,
                  borderRadius: AppRadius.ubinIkon10,
                ),
                child: Icon(
                  lucideIconFor(item.icon),
                  size: AppSpacing.iconSize20,
                  color: AppColors.utama,
                ),
              ),
              const SizedBox(width: AppSpacing.grid12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTypography.judulBaris),
                    const SizedBox(height: AppSpacing.grid2),
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: AppTypography.meta.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.utama,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.grid8),
                        Text(
                          '· ${item.steps.length} langkah',
                          style: AppTypography.meta.copyWith(
                            color: AppColors.teksSekunder,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.grid6),
          Text(
            item.description,
            style: AppTypography.meta.copyWith(color: AppColors.teksSekunder),
          ),
          const SizedBox(height: AppSpacing.grid10),
          SizedBox(
            height: AppSpacing.buttonHeightParent,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onApply,
              icon: const Icon(LucideIcons.plus, size: AppSpacing.iconSize16),
              label: const Text('Tambahkan ke Jadwal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.utama,
                side: const BorderSide(color: AppColors.utama),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.tombolOrangTua,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
