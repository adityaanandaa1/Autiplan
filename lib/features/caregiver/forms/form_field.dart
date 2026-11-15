import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          Flexible(child: Text(text, style: AppTypography.meta)),
          if (optional != null) ...[
            const SizedBox(width: AppSpacing.grid6),
            Flexible(
              child: Text(
                optional!,
                style: AppTypography.mikro.copyWith(
                  color: AppColors.teksSekunder,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kotak isian dengan latar `latar`, sudut 12. [focused] menggambar cincin
/// `utama` setebal [AppSpacing.strokeFocus] di dalam kotak (tanpa mengubah
/// ukuran isinya).
class FormBox extends StatelessWidget {
  const FormBox({
    super.key,
    required this.child,
    this.padding,
    this.focused = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final bool focused;

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
      // Selalu ada (transparan saat tidak aktif): bila dekorasi depan muncul
      // dan hilang, Container menambah/membuang satu lapis di atas isinya, dan
      // TextField di dalamnya dibuat ulang sehingga fokus dan keyboard hilang.
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadius.kolomIsian,
        border: Border.all(
          color: focused ? AppColors.utama : AppColors.transparan,
          width: AppSpacing.strokeFocus,
        ),
      ),
      child: child,
    );
  }
}

/// Kolom teks satu baris di dalam [FormBox]. Kotak abu-abu itulah kolomnya:
/// tidak ada garis tepi lain, hanya cincin `utama` saat kolom aktif.
class FormTextField extends StatefulWidget {
  const FormTextField({
    super.key,
    required this.controller,
    this.hint,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final String? hint;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Pesan validasi tenang di bawah kotak (bukan merah, mengikuti §8.4).
  final String? errorText;

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorText = widget.errorText;
    final field = FormBox(
      focused: _focusNode.hasFocus,
      // Tinggi 48 dp dipegang `constraints` pada dekorasi (target sentuh dan
      // node semantik TextField tetap 48), jadi padding vertikal kotak dibuang.
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.grid14),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        maxLength: widget.maxLength,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textAlignVertical: TextAlignVertical.center,
        obscureText: widget.obscureText,
        style: AppTypography.isi,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.isiHint,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.grid12,
          ),
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minTouchTarget,
          ),
        ),
      ),
    );
    if (errorText == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.grid6),
          child: Text(
            errorText,
            style: AppTypography.meta.copyWith(color: AppColors.saranTeks),
          ),
        ),
      ],
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
  const FormInfoBox({
    super.key,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

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
            LucideIcons.info,
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
