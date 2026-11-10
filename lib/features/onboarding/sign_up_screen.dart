import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/caregiver_header.dart';
import '../../data/auth_service.dart';
import '../../data/providers.dart';
import '../caregiver/forms/form_field.dart';

/// `/daftar`: buat akun orang tua dengan email + kata sandi.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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
    if (password.length < 8) {
      setState(() => _message = 'Kata sandi minimal 8 karakter.');
      return;
    }
    setState(() {
      _submitting = true;
      _message = null;
    });
    try {
      await ref.read(sessionNotifierProvider.notifier).signUp(email, password);
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
              title: 'Daftar',
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
                    label: 'Buat akun',
                    enabled: !_submitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.grid16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: AppTypography.isi.copyWith(
                          color: AppColors.teksSekunder,
                        ),
                      ),
                      AppTextButton(
                        label: 'Masuk',
                        onPressed: () => context.go('/masuk'),
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
