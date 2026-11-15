import 'package:autiplan/data/auth_service.dart';

class FakeAuthService implements AuthService {
  String? _uid;
  String? signUpError;
  String? signInError;

  @override
  String? get uid => _uid;

  @override
  Future<String?> idToken() async => 'fake-token';

  @override
  Future<void> signUp(String email, String password) async {
    final err = signUpError;
    if (err != null) throw AuthException(err);
    _uid = 'user_${email.hashCode}';
  }

  @override
  Future<void> signIn(String email, String password) async {
    final err = signInError;
    if (err != null) throw AuthException(err);
    _uid = 'user_${email.hashCode}';
  }

  /// Isi untuk membuat [sendPasswordReset] melempar galat tersebut.
  AuthException? resetError;
  final List<String> resetEmails = [];

  /// Isi untuk membuat verifikasi/konfirmasi kode melempar galat tersebut.
  AuthException? codeError;
  final List<String> verifiedCodes = [];
  final List<(String, String)> confirmed = [];

  @override
  Future<void> sendPasswordReset(String email) async {
    resetEmails.add(email);
    final err = resetError;
    if (err != null) throw err;
  }

  @override
  Future<void> verifyPasswordResetCode(String code) async {
    verifiedCodes.add(code);
    final err = codeError;
    if (err != null) throw err;
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    final err = codeError;
    if (err != null) throw err;
    confirmed.add((code, newPassword));
  }

  @override
  Future<String> signInAnonymously() async {
    _uid = 'anon_123';
    return _uid!;
  }

  @override
  Future<void> signOut() async {
    _uid = null;
  }
}
