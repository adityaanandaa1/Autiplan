import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:flutter_test/flutter_test.dart';

import 'package:autiplan/data/auth_service.dart';

/// FirebaseAuth palsu: setiap panggilan melempar galat yang diberikan.
class _ThrowingAuth implements fa.FirebaseAuth {
  _ThrowingAuth(this.error);

  final Object error;

  @override
  Future<fa.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw error;

  @override
  Future<fa.UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async => throw error;

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    fa.ActionCodeSettings? actionCodeSettings,
  }) async => throw error;

  @override
  Future<fa.UserCredential> signInAnonymously() async => throw error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const fallback = 'Belum bisa masuk. Coba lagi sebentar.';

  final errors = <String, Object>{
    'SocketException': const SocketException('tanpa internet'),
    'TimeoutException': TimeoutException('lama'),
    'StateError': StateError('aneh'),
  };

  for (final entry in errors.entries) {
    test('galat ${entry.key} menjadi AuthException berpesan umum', () async {
      final service = FirebaseAuthService(_ThrowingAuth(entry.value));
      final calls = <Future<void> Function()>[
        () => service.signUp('a@b.c', 'password1'),
        () => service.signIn('a@b.c', 'password1'),
        () => service.sendPasswordReset('a@b.c'),
        () => service.signInAnonymously(),
      ];
      for (final call in calls) {
        await expectLater(
          call(),
          throwsA(
            isA<AuthException>().having((e) => e.message, 'message', fallback),
          ),
        );
      }
    });
  }

  test('FirebaseAuthException tetap dipetakan lewat kodenya', () async {
    final service = FirebaseAuthService(
      _ThrowingAuth(fa.FirebaseAuthException(code: 'email-already-in-use')),
    );
    await expectLater(
      service.signUp('a@b.c', 'password1'),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          'Email ini sudah terdaftar.',
        ),
      ),
    );
  });
}
