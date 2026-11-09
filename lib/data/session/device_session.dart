// Sesi perangkat: siapa yang sedang memakai HP ini.
///
/// Disimpan di `shared_preferences` supaya aplikasi bisa dibuka tanpa internet.
sealed class DeviceSession {
  const DeviceSession();
}

/// Belum masuk (atau sudah keluar / putus dari keluarga).
class UnlinkedSession extends DeviceSession {
  const UnlinkedSession();
}

/// HP orang tua. [familyId] sama dengan `uid` akun orang tua.
class CaregiverSession extends DeviceSession {
  const CaregiverSession({required this.familyId});

  final String familyId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaregiverSession && familyId == other.familyId;

  @override
  int get hashCode => familyId.hashCode;
}

/// HP anak. [childId] menunjuk ke dokumen `children/{childId}` di keluarga.
class ChildSession extends DeviceSession {
  const ChildSession({required this.familyId, required this.childId});

  final String familyId;
  final String childId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildSession &&
          familyId == other.familyId &&
          childId == other.childId;

  @override
  int get hashCode => Object.hash(familyId, childId);
}
