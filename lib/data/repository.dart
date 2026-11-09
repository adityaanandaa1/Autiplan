import 'models/app_state.dart';

/// Sumber dan tujuan data aplikasi.
///
/// Layar tidak memanggil ini langsung: perubahan lewat
/// `appStateProvider.notifier.updateState`, yang meneruskannya ke [apply].
abstract class AutiPlanRepository {
  /// State terbaru. Beremisi pertama kali setelah semua koleksi memberi
  /// snapshot pertama, lalu setiap ada perubahan (dari HP ini maupun HP lain).
  Stream<AppState> watch();

  /// Menulis selisih [before] -> [after]. Future-nya bisa tidak pernah selesai
  /// selama HP tanpa internet, jadi pemanggil di jalur UI tidak boleh
  /// menunggunya.
  Future<void> apply(AppState before, AppState after);
}
