import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_api.dart';
import 'providers.dart';
import 'session/device_session.dart';

/// [BackendApi] tanpa backend (WORKER_URL kosong): push tidak dikirim, kode
/// pasangan tidak bisa dibuat.
class NoopBackendApi implements BackendApi {
  const NoopBackendApi();

  @override
  Future<PairingCode> createPairingCode(String childId) =>
      Future.error(const BackendException(BackendFailure.unknown));

  @override
  Future<ClaimedLink> claimPairingCode(String code) =>
      Future.error(const BackendException(BackendFailure.unknown));

  @override
  Future<void> notify(String familyId, String notificationId) async {}
}

/// Mengirim push ke orang tua untuk notifikasi [notificationId] setelah
/// [written] (penulisan Firestore) selesai, supaya Worker tidak membaca
/// dokumen yang belum ada. Tidak menunggu apa pun dan tidak pernah melempar,
/// sehingga navigasi anak tidak bisa tertahan. Hanya untuk sesi anak.
void notifyParentAfterWrite(
  WidgetRef ref, {
  required Future<void> written,
  required String notificationId,
  required String label,
}) {
  try {
    final session = ref.read(sessionProvider);
    if (session is! ChildSession || session.familyId.isEmpty) return;
    final familyId = session.familyId;
    final api = ref.read(backendApiProvider);
    written
        .then((_) => api.notify(familyId, notificationId))
        .catchError((Object e) => debugPrint('Gagal push $label: $e'));
  } catch (e) {
    debugPrint('Gagal push $label: $e');
  }
}
