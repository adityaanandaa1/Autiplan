import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../forms/form_field.dart';

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
    required this.onDayToggled,
    required this.onIndependentChanged,
  });

  final String childName;
  final List<TextEditingController> stepControllers;
  final Set<int> repeatWeekdays;
  final TextEditingController shortTitleController;
  final bool independentMode;
  final VoidCallback onAddStep;
  final ValueChanged<int> onRemoveStep;
  final ValueChanged<int> onDayToggled;
  final ValueChanged<bool> onIndependentChanged;

  @override
  Widget build(BuildContext context) {
    const daysName = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.grid16),
        FormLabel('Langkah-langkah untuk $childName', optional: '(0–5 langkah)'),
        ...List.generate(stepControllers.length, (idx) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.grid8),
            child: Row(
              children: [
                Text('${idx + 1}. ', style: AppTypography.meta),
                Expanded(
                  child: FormTextField(
                    controller: stepControllers[idx],
                    hint: 'Langkah ${idx + 1}',
                    maxLength: 60,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: AppSpacing.iconSize18),
                  color: AppColors.bahaya,
                  onPressed: () => onRemoveStep(idx),
                ),
              ],
            ),
          );
        }),
        if (stepControllers.length < 5)
          AppTextButton(
            label: '+ Tambah langkah',
            onPressed: onAddStep,
          ),
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
        ),
        const SizedBox(height: AppSpacing.grid12),
        SwitchListTile(
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
      ],
    );
  }
}
