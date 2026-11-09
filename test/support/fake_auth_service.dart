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

  @override
  Future<void> sendPasswordReset(String email) async {}

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
