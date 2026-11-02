import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/activity_icon_data.dart';
import '../../../data/models/activity_icon.dart';
import 'sheet_scaffold.dart';

/// Sheet pemilih ikon (grid 3×3, urutan tetap §6).
Future<ActivityIcon?> showIconPickerSheet(
  BuildContext context, {
  ActivityIcon? selected,
}) {
  return showModalBottomSheet<ActivityIcon>(
    context: context,
    backgroundColor: AppColors.transparan,
    isScrollControlled: true,
    builder: (ctx) => SheetScaffold(
      title: 'Pilih ikon',
      subtitle: '9 ikon tersedia',
      child: _IconGrid(selected: selected),
    ),
  );
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({this.selected});

  final ActivityIcon? selected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.grid12,
      crossAxisSpacing: AppSpacing.grid12,
      childAspectRatio: 1.15,
      children: ActivityIcon.values.map((icon) {
        final isSelected = icon == selected;
        return InkWell(
          onTap: () => Navigator.of(context).pop(icon),
          borderRadius: AppRadius.ubinIkon10,
          child: Semantics(
            label: activityIconLabel(icon),
            button: true,
            selected: isSelected,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColors.utamaLembut : AppColors.latar,
                borderRadius: AppRadius.ubinIkon10,
                border: isSelected
                    ? Border.all(
                        color: AppColors.utama,
                        width: AppSpacing.strokeAccent,
                      )
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    lucideIconFor(icon),
                    size: AppSpacing.iconSize24,
                    color: isSelected ? AppColors.utama : AppColors.teks,
                  ),
                  const SizedBox(height: AppSpacing.grid6),
                  Text(activityIconLabel(icon), style: AppTypography.meta),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
