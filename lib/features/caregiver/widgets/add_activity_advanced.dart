import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../forms/form_field.dart';

/// Bagian terbuka "Opsi lanjutan" (OT-08): langkah (tambah/hapus/urutkan),
/// ulangi tiap minggu, nama singkat untuk anak, dan Mode mandiri.
class AddActivityAdvanced extends StatelessWidget {
  const AddActivityAdvanced({
    super.key,
    required this.childName,
    required this.stepControllers,
    required this.repeatWeekdays,
    required this.shortTitleController,
    required this.independentMode,
    required this.onAddStep,
    required this.onRemoveStep,
    required this.onReorderStep,
    required this.onDayToggled,
    required this.onShortTitleChanged,
    required this.onIndependentChanged,
    this.shortTitleError,
  });

  final String childName;
  final List<TextEditingController> stepControllers;
  final Set<int> repeatWeekdays;
  final TextEditingController shortTitleController;
  final bool independentMode;
  final VoidCallback onAddStep;
  final ValueChanged<int> onRemoveStep;

  /// (indeks lama, indeks baru) setelah penyesuaian `newIndex` Flutter.
  final void Function(int oldIndex, int newIndex) onReorderStep;
  final ValueChanged<int> onDayToggled;
  final ValueChanged<String> onShortTitleChanged;
  final ValueChanged<bool> onIndependentChanged;
  final String? shortTitleError;

  @override
  Widget build(BuildContext context) {
    const daysName = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.grid16),
        FormLabel(
          'Langkah-langkah untuk $childName',
          optional: '(0–5 langkah)',
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) {
            if (newIndex != oldIndex) onReorderStep(oldIndex, newIndex);
          },
          children: [
            for (var idx = 0; idx < stepControllers.length; idx++)
              Padding(
                key: ObjectKey(stepControllers[idx]),
                padding: const EdgeInsets.only(bottom: AppSpacing.grid8),
                child: Row(
                  children: [
                    ReorderableDragStartListener(
                      index: idx,
                      child: Semantics(
                        label: 'Geser langkah ${idx + 1}',
                        child: const SizedBox(
                          width: AppSpacing.minTouchTarget,
                          height: AppSpacing.minTouchTarget,
                          child: Icon(
                            LucideIcons.gripVertical,
                            size: AppSpacing.iconSize18,
                            color: AppColors.teksSekunder,
                          ),
                        ),
                      ),
                    ),
                    Text('${idx + 1}. ', style: AppTypography.meta),
                    Expanded(
                      child: FormTextField(
                        controller: stepControllers[idx],
                        hint: 'Langkah ${idx + 1}',
                        maxLength: 60,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus langkah ${idx + 1}',
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: AppSpacing.iconSize18,
                      ),
                      color: AppColors.bahaya,
                      onPressed: () => onRemoveStep(idx),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (stepControllers.length < 5)
          AppTextButton(label: '+ Tambah langkah', onPressed: onAddStep),
        const SizedBox(height: AppSpacing.grid12),
        const FormLabel('Ulangi tiap minggu'),
        Wrap(
          spacing: AppSpacing.grid6,
          children: List.generate(7, (i) {
            final day = i + 1;
            final sel = repeatWeekdays.contains(day);
            return FilterChip(
              label: Text(daysName[i]),
              selected: sel,
              selectedColor: AppColors.utamaLembut,
              backgroundColor: AppColors.latar,
              showCheckmark: false,
              labelStyle: AppTypography.meta.copyWith(
                color: sel ? AppColors.utama : AppColors.teks,
              ),
              onSelected: (_) => onDayToggled(day),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.grid12),
        FormLabel('Nama singkat untuk $childName', optional: '(maks 2 kata)'),
        FormTextField(
          controller: shortTitleController,
          hint: 'Bawaan: 2 kata pertama',
          maxLength: 30,
          onChanged: onShortTitleChanged,
          errorText: shortTitleError,
        ),
        const SizedBox(height: AppSpacing.grid12),
        // SwitchListTile butuh ancestor Material; sheet hanya DecoratedBox.
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mode mandiri', style: AppTypography.judulBaris),
            subtitle: Text(
              'Langkah diringkas untuk $childName',
              style: AppTypography.meta,
            ),
            value: independentMode,
            activeThumbColor: AppColors.utama,
            onChanged: onIndependentChanged,
          ),
        ),
      ],
    );
  }
}
