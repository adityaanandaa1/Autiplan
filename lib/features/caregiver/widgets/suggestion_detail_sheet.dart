import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
              Text(
                (suggestion.payload['detailBody'] as String?) ??
                    suggestion.body,
                style: AppTypography.isiDetail,
              ),
              const SizedBox(height: AppSpacing.grid16),
              _WhyBox(suggestion: suggestion),
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
            LucideIcons.lightbulb,
            size: AppSpacing.iconSize20,
            color: AppColors.saranTeks,
          ),
        ),
        const SizedBox(width: AppSpacing.grid12),
        Expanded(child: Text(title, style: AppTypography.judulSheet)),
        IconButton(
          tooltip: 'Tutup',
          icon: const Icon(LucideIcons.x, size: AppSpacing.iconSize24),
          color: AppColors.teksSekunder,
          onPressed: onClose,
        ),
      ],
    );
  }
}

/// Kotak "Kenapa saran ini?" (OT-17): Data, Dasar, dan catatan tambahan.
class _WhyBox extends StatelessWidget {
  const _WhyBox({required this.suggestion});

  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final steps = suggestion.payload['originalSteps'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.grid16),
      decoration: const BoxDecoration(
        color: AppColors.latar,
        borderRadius: AppRadius.kolomIsian,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kenapa saran ini?', style: AppTypography.judulBaris),
          const SizedBox(height: AppSpacing.grid8),
          _labelled('Data: ', suggestion.reasonData),
          const SizedBox(height: AppSpacing.grid8),
          _labelled('Dasar: ', suggestion.reasonBasis),
          if (suggestion.type == SuggestionType.independence &&
              steps is int) ...[
            const SizedBox(height: AppSpacing.grid8),
            Text(
              'Bisa dikembalikan ke $steps langkah kapan saja.',
              style: AppTypography.meta,
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelled(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: AppTypography.kecil.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: value),
        ],
      ),
      style: AppTypography.kecil,
    );
  }
}

void dismissSuggestion(
  BuildContext context,
  WidgetRef ref,
  Suggestion suggestion,
) {
  final state = ref.read(appStateProvider);
  ref
      .read(appStateProvider.notifier)
      .updateState(
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
