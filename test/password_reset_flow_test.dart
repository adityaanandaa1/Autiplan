import 'package:autiplan/data/auth_service.dart';
import 'package:autiplan/data/providers.dart';
import 'package:autiplan/features/onboarding/check_email_screen.dart';
import 'package:autiplan/features/onboarding/reset_password_screen.dart';
import 'package:autiplan/features/onboarding/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  Widget wrapRouter(String initial) {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/masuk', builder: (_, _) => const SignInScreen()),
        GoRoute(
          path: '/cek-email',
          builder: (_, s) =>
              CheckEmailScreen(email: s.uri.queryParameters['email'] ?? ''),
        ),
        GoRoute(
          path: '/atur-ulang',
          builder: (_, s) =>
              ResetPasswordScreen(code: s.uri.queryParameters['oobCode']),
        ),
      ],
    );
    return ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SignInScreen lupa kata sandi', () {
    testWidgets('email kosong tidak mengirim', (tester) async {
      await tester.pumpWidget(wrapRouter('/masuk'));
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pump();
      expect(
        find.text('Isi email dulu, lalu tekan Lupa kata sandi.'),
        findsOneWidget,
      );
      expect(auth.resetEmails, isEmpty);
    });

    testWidgets('email terisi menuju /cek-email', (tester) async {
      await tester.pumpWidget(wrapRouter('/masuk'));
      await tester.enterText(find.byType(TextField).first, 'a@b.com');
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      expect(auth.resetEmails, ['a@b.com']);
      expect(
        find.text(
          'Kami mengirim tautan ke a@b.com, kalau email itu terdaftar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('email tidak terdaftar tetap menuju /cek-email', (
      tester,
    ) async {
      auth.resetError = const AuthException(
        'Email atau kata sandi belum cocok.',
      );
      await tester.pumpWidget(wrapRouter('/masuk'));
      await tester.enterText(find.byType(TextField).first, 'x@y.com');
      await tester.tap(find.text('Lupa kata sandi?'));
      await tester.pumpAndSettle();
      expect(find.text('Buka email di HP ini.'), findsOneWidget);
    });
  });

  group('CheckEmailScreen', () {
    testWidgets('menampilkan isi, jeda kirim ulang, lalu kirim ulang', (
      tester,
    ) async {
      await tester.pumpWidget(wrapRouter('/cek-email?email=a%40b.com'));
      await tester.pump();
      expect(find.text('Cek email kamu'), findsOneWidget);
      expect(find.text('Buka email di HP ini.'), findsOneWidget);
      expect(find.text('Tekan tautan di dalamnya.'), findsOneWidget);
      expect(find.text('Buat kata sandi baru.'), findsOneWidget);
      expect(find.text('Tidak ketemu? Lihat folder spam.'), findsOneWidget);

      ElevatedButton resend() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Kirim ulang tautan (30)'),
      );
      expect(resend().onPressed, isNull);

      await tester.pump(const Duration(seconds: 30));
      final btn = find.widgetWithText(ElevatedButton, 'Kirim ulang tautan');
      expect(tester.widget<ElevatedButton>(btn).onPressed, isNotNull);

      await tester.tap(btn);
      await tester.pump();
      expect(auth.resetEmails, ['a@b.com']);
      // Hitung mundur mulai lagi.
      expect(find.text('Kirim ulang tautan (30)'), findsOneWidget);
      await tester.pump(const Duration(seconds: 31));
    });

    testWidgets('Kembali ke Masuk membuka layar Masuk', (tester) async {
      await tester.pumpWidget(wrapRouter('/cek-email?email=a%40b.com'));
      await tester.tap(find.text('Kembali ke Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(wrapRouter('/atur-ulang?oobCode=ABC'));
      await tester.pumpAndSettle();
    }

    testWidgets('kata sandi terlalu pendek', (tester) async {
      await open(tester);
      expect(auth.verifiedCodes, ['ABC']);
      await tester.enterText(find.byType(TextField).at(0), 'pendek');
      await tester.enterText(find.byType(TextField).at(1), 'pendek');
      await tester.tap(find.text('Simpan kata sandi'));
      await tester.pump();
      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);
      expect(auth.confirmed, isEmpty);
    });

    testWidgets('kata sandi tidak sama', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).at(0), 'panjang123');
      await tester.enterText(find.byType(TextField).at(1), 'panjang124');
      await tester.tap(find.text('Simpan kata sandi'));
      await tester.pump();
      expect(find.text('Kata sandi belum sama.'), findsOneWidget);
      expect(auth.confirmed, isEmpty);
    });

    testWidgets('sukses menyimpan lalu kembali ke Masuk', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField).at(0), 'panjang123');
      await tester.enterText(find.byType(TextField).at(1), 'panjang123');
      await tester.tap(find.text('Simpan kata sandi'));
      await tester.pumpAndSettle();
      expect(auth.confirmed, [('ABC', 'panjang123')]);
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
      expect(
        find.text('Kata sandi sudah diganti. Silakan masuk.'),
        findsOneWidget,
      );
    });

    testWidgets('kode tidak valid menampilkan keadaan tenang', (tester) async {
      auth.codeError = const InvalidResetCodeException();
      await open(tester);
      expect(
        find.text('Tautan ini sudah tidak berlaku. Minta tautan baru.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Ke halaman Masuk'));
      await tester.pumpAndSettle();
      expect(find.text('Lupa kata sandi?'), findsOneWidget);
    });
  });
}
