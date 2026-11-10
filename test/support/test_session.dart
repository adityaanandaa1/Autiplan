import 'package:autiplan/data/session/device_session.dart';

/// Sesi orang tua bawaan untuk widget test. Sejak Tahap 10 data dan rute
/// bergantung pada `sessionProvider`; tes tidak perlu Firebase Auth, cukup
/// `sessionProvider.overrideWithValue(testCaregiverSession)`.
const testCaregiverSession = CaregiverSession(familyId: 'keluarga-tes');

/// Sesi HP anak bawaan untuk widget test Tahap 11 (layar anak membaca
/// `ChildSession.childId` lewat `currentChildProvider`).
const testChildSession = ChildSession(
  familyId: 'keluarga-tes',
  childId: 'anak-tes',
);
