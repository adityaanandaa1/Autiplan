import 'package:autiplan/data/backend_api.dart';

/// [BackendApi] palsu untuk tes. Atur [nextFailure] / [nextError] agar
/// panggilan berikutnya gagal, dan [nextLink] untuk hasil klaim.
class FakeBackendApi implements BackendApi {
  /// Bila diisi, create/claim melempar [BackendException] dengan galat ini.
  BackendFailure? nextFailure;

  /// Bila diisi, create/claim melempar objek ini apa adanya.
  Object? nextError;

  ClaimedLink? nextLink;

  String code = '654321';

  int createCalls = 0;
  int claimCalls = 0;
  int notifyCalls = 0;
  final List<String> claimedCodes = [];

  void _maybeFail() {
    final error = nextError;
    if (error != null) throw error;
    final f = nextFailure;
    if (f != null) throw BackendException(f);
  }

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    createCalls += 1;
    _maybeFail();
    return PairingCode(code: code, expiresAt: DateTime(2026, 5, 1, 16, 10));
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    claimCalls += 1;
    claimedCodes.add(code);
    _maybeFail();
    return nextLink ??
        const ClaimedLink(familyId: 'fam-test', childId: 'child-test');
  }

  @override
  Future<void> notify(String familyId, String notificationId) async {
    notifyCalls += 1;
  }
}
