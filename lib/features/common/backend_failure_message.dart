import '../../data/backend_api.dart';

/// Pesan tenang untuk [BackendFailure], tanpa kata teknis. Teks berbeda
/// untuk HP anak yang memasukkan kode dan untuk orang tua yang membuat kode.
extension BackendFailureMessage on BackendFailure {
  /// HP anak memakai kode (`/hubungkan`).
  String get claimMessage => switch (this) {
    BackendFailure.invalidCode => 'Kode belum cocok. Coba periksa lagi.',
    BackendFailure.expiredCode => 'Kode sudah tidak berlaku. Minta kode baru.',
    BackendFailure.tooManyAttempts =>
      'Terlalu banyak percobaan. Coba lagi nanti.',
    BackendFailure.offline => 'Belum ada internet. Coba lagi nanti.',
    BackendFailure.unknown => 'Belum bisa menghubungkan. Coba lagi sebentar.',
  };

  /// Orang tua membuat kode (sheet pairing).
  String get createMessage => switch (this) {
    BackendFailure.offline => 'Belum ada internet. Coba lagi nanti.',
    BackendFailure.invalidCode => 'Anak belum bisa dihubungkan. Coba lagi.',
    BackendFailure.expiredCode => 'Kode sudah tidak berlaku. Buat kode baru.',
    BackendFailure.tooManyAttempts => 'Coba lagi sebentar lagi.',
    BackendFailure.unknown => 'Belum bisa membuat kode. Coba lagi sebentar.',
  };
}
