import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/calm_snackbar.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/auth_service.dart';
import '../../data/providers.dart';
import '../caregiver/forms/form_field.dart';

enum _CodeState { checking, valid, invalid, failed }

/// `/atur-ulang?oobCode=...`: buat kata sandi baru dari tautan email.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.code});

  final String? code;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  _CodeState _codeState = _CodeState.checking;
  String? _message;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = widget.code;
    if (code == null || code.isEmpty) {
      _codeState = _CodeState.invalid;
      return;
    }
    try {
      await ref.read(authServiceProvider).verifyPasswordResetCode(code);
      if (mounted) setState(() => _codeState = _CodeState.valid);
    } on InvalidResetCodeException {
      if (mounted) setState(() => _codeState = _CodeState.invalid);
    } on Object {
      if (mounted) setState(() => _codeState = _CodeState.failed);
    }
  }

  Future<void> _submit() async {
    final password = _password.text;
    if (password.length < 8) {
      setState(() => _message = 'Kata sandi minimal 8 karakter.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _message = 'Kata sandi belum sama.');
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    var done = false;
    try {
      await ref
          .read(authServiceProvider)
          .confirmPasswordReset(widget.code!, password);
      done = true;
    } on InvalidResetCodeException {
      if (mounted) setState(() => _codeState = _CodeState.invalid);
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } on Object {
      if (mounted) setState(() => _message = authFallbackMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (done && mounted) {
      CalmSnackbar.show(
        context,
        message: 'Kata sandi sudah diganti. Silakan masuk.',
      );
      context.go('/masuk');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.permukaan,
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Kata sandi baru',
              variant: CaregiverHeaderVariant.back,
              onBack: () => context.go('/masuk'),
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_codeState) {
      case _CodeState.checking:
        return const Center(
          child: SizedBox(
            width: AppSpacing.iconSize24,
            height: AppSpacing.iconSize24,
            child: CircularProgressIndicator(
              strokeWidth: AppSpacing.grid2,
              color: AppColors.utama,
            ),
          ),
        );
      case _CodeState.invalid:
        return _notice('Tautan ini sudah tidak berlaku. Minta tautan baru.');
      case _CodeState.failed:
        return _notice(authFallbackMessage);
      case _CodeState.valid:
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.grid16),
          children: [
            const FormLabel('Kata sandi baru'),
            FormTextField(
              controller: _password,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              onChanged: (_) => setState(() => _message = null),
            ),
            const SizedBox(height: AppSpacing.grid16),
            const FormLabel('Ulangi kata sandi baru'),
            FormTextField(
              controller: _confirm,
              keyboardType: TextInputType.visiblePassword,
              obscureText: true,
              onChanged: (_) => setState(() => _message = null),
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.grid8),
              Text(
                _message!,
                style: AppTypography.meta.copyWith(color: AppColors.saranTeks),
              ),
            ],
            const SizedBox(height: AppSpacing.grid16),
            _submitting
                ? const Center(
                    child: SizedBox(
                      width: AppSpacing.iconSize24,
                      height: AppSpacing.iconSize24,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSpacing.grid2,
                        color: AppColors.utama,
                      ),
                    ),
                  )
                : PrimaryButton(label: 'Simpan kata sandi', onPressed: _submit),
          ],
        );
    }
  }

  Widget _notice(String text) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.grid16),
      children: [
        Text(text, style: AppTypography.isi),
        const SizedBox(height: AppSpacing.grid24),
        PrimaryButton(
          label: 'Ke halaman Masuk',
          onPressed: () => context.go('/masuk'),
        ),
      ],
    );
  }
}
