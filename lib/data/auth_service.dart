import 'package:firebase_auth/firebase_auth.dart' as fa;

/// Antarmuka autentikasi yang dipakai layar.
///
/// Layar tidak boleh mengimpor `firebase_auth`; semua lewat [AuthService]
/// (dan versi palsunya di tes).
abstract class AuthService {
  /// UID akun yang sedang masuk, atau null bila belum masuk.
  String? get uid;

  /// ID token Firebase untuk dipakai Worker (Tahap 11+).
  Future<String?> idToken();

  Future<void> signUp(String email, String password);

  Future<void> signIn(String email, String password);

  Future<void> sendPasswordReset(String email);

  /// Memastikan kode dari tautan atur ulang masih berlaku. Melempar
  /// [InvalidResetCodeException] bila kode kedaluwarsa, sudah dipakai, atau salah.
  Future<void> verifyPasswordResetCode(String code);

  /// Menyimpan kata sandi baru memakai kode dari tautan atur ulang.
  Future<void> confirmPasswordReset(String code, String newPassword);

  /// Masuk anonim untuk HP anak. Mengembalikan uid.
  Future<String> signInAnonymously();

  Future<void> signOut();
}

/// Pesan umum untuk galat apa pun yang tidak dikenal (mis. tanpa internet).
const String authFallbackMessage = 'Belum bisa masuk. Coba lagi sebentar.';

/// Galat autentikasi dengan pesan yang sudah diterjemahkan ke bahasa yang
/// tenang dan tanpa kata teknis. Layar cukup menampilkan [message].
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Kode atur ulang kata sandi sudah tidak berlaku (kedaluwarsa, sudah dipakai,
/// atau tidak valid). Layar membedakannya dari galat lain lewat tipe ini.
class InvalidResetCodeException extends AuthException {
  const InvalidResetCodeException()
    : super('Tautan ini sudah tidak berlaku. Minta tautan baru.');
}

/// Implementasi nyata di atas `firebase_auth`.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final fa.FirebaseAuth _auth;

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  @override
  Future<void> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    } catch (_) {
      throw const AuthException(authFallbackMessage);
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    } catch (_) {
      throw const AuthException(authFallbackMessage);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    } catch (_) {
      throw const AuthException(authFallbackMessage);
    }
  }

  @override
  Future<void> verifyPasswordResetCode(String code) async {
    try {
      await _auth.verifyPasswordResetCode(code);
    } on fa.FirebaseAuthException catch (e) {
      throw _resetError(e.code);
    }
  }

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
    } on fa.FirebaseAuthException catch (e) {
      throw _resetError(e.code);
    }
  }

  static AuthException _resetError(String code) {
    switch (code) {
      case 'expired-action-code':
      case 'invalid-action-code':
        return const InvalidResetCodeException();
      default:
        return AuthException(_messageFor(code));
    }
  }

  @override
  Future<String> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential.user?.uid ?? '';
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    } catch (_) {
      throw const AuthException(authFallbackMessage);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Memetakan kode Firebase ke tiga pesan tenang di tabel, sisanya ke pesan
  /// umum (disetujui pengguna 11 November 2026).
  static String _messageFor(String code) {
    switch (code) {
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'invalid-email':
      case 'user-disabled':
      case 'user-token-expired':
        return 'Email atau kata sandi belum cocok.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar.';
      case 'weak-password':
        return 'Kata sandi minimal 8 karakter.';
      default:
        return authFallbackMessage;
    }
  }
}
