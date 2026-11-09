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

/// `/masuk`: masuk akun orang tua dengan email + kata sandi.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _message;
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Email atau kata sandi belum cocok.');
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(sessionNotifierProvider.notifier).signIn(email, password);
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    setState(() => _message = null);
    try {
      await ref.read(authServiceProvider).sendPasswordReset(email);
      if (mounted) {
        CalmSnackbar.show(
          context,
          message: 'Tautan untuk mengganti kata sandi sudah dikirim.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            CaregiverHeader(
              title: 'Masuk',
              variant: CaregiverHeaderVariant.back,
              onBack: () => context.go('/mulai'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.grid16),
                children: [
                  const FormLabel('Email'),
                  FormTextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _message = null),
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  const FormLabel('Kata sandi'),
                  FormTextField(
                    controller: _password,
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: true,
                    onChanged: (_) => setState(() => _message = null),
                  ),
                  const SizedBox(height: AppSpacing.grid8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppTextButton(
                      label: 'Lupa kata sandi?',
                      onPressed: _submitting ? null : _forgotPassword,
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.grid8),
                    Text(
                      _message!,
                      style: AppTypography.meta.copyWith(
                        color: AppColors.saranTeks,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.grid16),
                  PrimaryButton(
                    label: 'Masuk',
                    enabled: !_submitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: AppTypography.isi.copyWith(
                          color: AppColors.teksSekunder,
                        ),
                      ),
                      AppTextButton(
                        label: 'Daftar',
                        onPressed: () => context.go('/daftar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
