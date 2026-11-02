import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/calm_snackbar.dart';
import '../../../data/models/models.dart';
import '../../../data/providers.dart';
import 'suggestion_actions.dart';

/// Sheet Detail Saran (OT-17).
Future<void> showSuggestionDetailSheet(
  BuildContext context, {
  required Suggestion suggestion,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _SuggestionDetailBody(suggestion: suggestion),
  );
}

class _SuggestionDetailBody extends ConsumerWidget {
  const _SuggestionDetailBody({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.permukaan,
        borderRadius: AppRadius.sheetAtas,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.grid20,
            AppSpacing.grid16,
            AppSpacing.grid20,
            AppSpacing.grid24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                title: suggestion.title,
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppSpacing.grid16),
              Text(suggestion.body, style: AppTypography.isi),
              const SizedBox(height: AppSpacing.grid16),
              const _SectionLabel('Kenapa (data)'),
              Text(suggestion.reasonData, style: AppTypography.kecil),
              const SizedBox(height: AppSpacing.grid12),
              const _SectionLabel('Kenapa (dasar)'),
              Text(suggestion.reasonBasis, style: AppTypography.kecil),
              if (suggestion.type == SuggestionType.independence) ...[
                const SizedBox(height: AppSpacing.grid12),
                Text(
                  'Bisa dikembalikan kapan saja.',
                  style: AppTypography.meta.copyWith(
                    color: AppColors.teksSekunder,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.grid24),
              PrimaryButton(
                label: suggestion.actionLabel,
                onPressed: () =>
                    applySuggestionAction(context, ref, suggestion),
              ),
              AppTextButton(
                label: 'Nanti saja',
                onPressed: () => Navigator.of(context).pop(),
              ),
              AppTextButton(
                label: 'Abaikan saran ini',
                onPressed: () => dismissSuggestion(context, ref, suggestion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: AppSpacing.iconTile40,
          height: AppSpacing.iconTile40,
          decoration: const BoxDecoration(
            color: AppColors.saranLembut,
            borderRadius: AppRadius.ubinIkon10,
          ),
          child: const Icon(
            Icons.lightbulb_outline,
            size: AppSpacing.iconSize20,
            color: AppColors.saranTeks,
          ),
        ),
        const SizedBox(width: AppSpacing.grid12),
        Expanded(
          child: Text(title, style: AppTypography.judulSheet),
        ),
        IconButton(
          tooltip: 'Tutup',
          icon: const Icon(Icons.close, size: AppSpacing.iconSize24),
          color: AppColors.teksSekunder,
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grid6),
      child: Text(
        text,
        style: AppTypography.meta,
      ),
    );
  }
}

void dismissSuggestion(
  BuildContext context,
  WidgetRef ref,
  Suggestion suggestion,
) {
  final state = ref.read(appStateProvider);
  ref.read(appStateProvider.notifier).updateState(
        state.copyWith(
          suggestionStatus: {
            ...state.suggestionStatus,
            suggestion.id: SuggestionStatus.dismissed,
          },
        ),
      );
  Navigator.of(context).pop();
  CalmSnackbar.show(context, message: 'Saran diabaikan');
}
