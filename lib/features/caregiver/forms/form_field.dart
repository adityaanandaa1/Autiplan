import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Label kolom form (13 Medium sekunder).
class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key, this.optional});

  final String text;
  final String? optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.grid6),
      child: Row(
        children: [
          Text(text, style: AppTypography.meta),
          if (optional != null) ...[
            const SizedBox(width: AppSpacing.grid6),
            Text(
              optional!,
              style: AppTypography.mikro.copyWith(
                color: AppColors.teksSekunder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kotak isian dengan latar `latar`, sudut 12.
class FormBox extends StatelessWidget {
  const FormBox({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.grid14,
            vertical: AppSpacing.grid13,
          ),
      decoration: const BoxDecoration(
        color: AppColors.latar,
        borderRadius: AppRadius.kolomIsian,
      ),
      child: child,
    );
  }
}

/// Kolom teks satu baris di dalam [FormBox].
class FormTextField extends StatelessWidget {
  const FormTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return FormBox(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: AppTypography.isi,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.isiHint,
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

/// Baris tautan/aksi di dalam kotak isian (mis. "Ganti", "chevronRight").
class FormLinkRow extends StatelessWidget {
  const FormLinkRow({
    super.key,
    this.leading,
    required this.text,
    this.hint,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  final Widget? leading;
  final String? text;
  final String? hint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.kolomIsian,
      child: FormBox(
        child: Row(
          children: [
            ?leading,
            if (leading != null) const SizedBox(width: AppSpacing.grid12),
            Expanded(
              child: Text(
                text ?? hint ?? '',
                style: text != null ? AppTypography.isi : AppTypography.isiHint,
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Tautan teks utama (mis. "Lihat tampilan Dulu → Sekarang").
class FormTextLink extends StatelessWidget {
  const FormTextLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.pil,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.grid8),
        child: Text(label, style: AppTypography.tautanAksi),
      ),
    );
  }
}

/// Kotak info tenang (latar `saranLembut`, ikon info).
class FormInfoBox extends StatelessWidget {
  const FormInfoBox({super.key, required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.grid14),
      decoration: BoxDecoration(
        color: AppColors.saranLembut,
        borderRadius: AppRadius.kartuSaran,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: AppSpacing.iconSize20,
            color: AppColors.saranTeks,
          ),
          const SizedBox(width: AppSpacing.grid10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: AppTypography.kecil),
                if (actionLabel != null) ...[
                  const SizedBox(height: AppSpacing.grid4),
                  FormTextLink(label: actionLabel!, onTap: onAction ?? () {}),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
