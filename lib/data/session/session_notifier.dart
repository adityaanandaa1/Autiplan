import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth_service.dart';
import 'device_session.dart';

/// Mengelola sesi perangkat dan menyimpannya di `shared_preferences` supaya
/// aplikasi bisa dibuka tanpa internet.
///
/// - `signUp` / `signIn` membuat [CaregiverSession] dengan `familyId` = uid.
/// - `signOut` mengembalikan ke [UnlinkedSession].
/// - [ChildSession] memantau `devices/{uid}` miliknya; bila dokumen hilang
///   atau listener menerima `permission-denied`, sesi menjadi [UnlinkedSession].
class SessionNotifier extends StateNotifier<DeviceSession> {
  SessionNotifier(this._auth, this._prefs, {this._db, this._beforeSignOut})
    : super(const UnlinkedSession()) {
    _restore();
  }

  static const _prefsKey = 'autiplan_session';

  final AuthService _auth;
  final SharedPreferences _prefs;
  final fs.FirebaseFirestore? _db;

  /// Dipanggil sebelum keluar (mis. membatalkan push). Galatnya ditelan.
  final Future<void> Function()? _beforeSignOut;

  StreamSubscription<fs.DocumentSnapshot<Map<String, dynamic>>>? _deviceSub;

  Future<void> signUp(String email, String password) async {
    await _auth.signUp(email, password);
    final uid = _auth.uid;
    if (uid == null) {
      throw const AuthException('Belum bisa masuk. Coba lagi sebentar.');
    }
    _setCaregiver(uid);
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signIn(email, password);
    final uid = _auth.uid;
    if (uid == null) {
      throw const AuthException('Belum bisa masuk. Coba lagi sebentar.');
    }
    _setCaregiver(uid);
  }

  Future<void> signOut() async {
    try {
      await _beforeSignOut?.call();
    } on Object catch (e) {
      debugPrint('Pembatalan push gagal: $e');
    }
    await _auth.signOut();
    _clear();
  }

  /// Masuk anonim untuk HP anak (diklaim di Tahap 11).
  Future<void> signInAnonymously() => _auth.signInAnonymously();

  /// Memasang sesi anak setelah kode dipakai (Tahap 11) dan mulai memantau
  /// dokumen perangkatnya.
  void adoptChildSession({required String familyId, required String childId}) {
    _persist({'type': 'child', 'familyId': familyId, 'childId': childId});
    _watchChildDevice(familyId, childId);
    state = ChildSession(familyId: familyId, childId: childId);
  }

  void _setCaregiver(String familyId) {
    _persist({'type': 'caregiver', 'familyId': familyId});
    state = CaregiverSession(familyId: familyId);
  }

  void _restore() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final familyId = json['familyId'] as String;
      switch (json['type'] as String) {
        case 'caregiver':
          state = CaregiverSession(familyId: familyId);
        case 'child':
          final childId = json['childId'] as String;
          _watchChildDevice(familyId, childId);
          state = ChildSession(familyId: familyId, childId: childId);
        default:
          _clear();
      }
    } on Object catch (e) {
      debugPrint('Sesi tersimpan tidak terbaca: $e');
      _clear();
    }
  }

  void _clear() {
    unawaited(_prefs.remove(_prefsKey));
    unawaited(_deviceSub?.cancel());
    _deviceSub = null;
    state = const UnlinkedSession();
  }

  void _persist(Map<String, dynamic> json) {
    unawaited(_prefs.setString(_prefsKey, jsonEncode(json)));
  }

  /// Apakah snapshot `devices/{uid}` berarti HP anak ini sudah diputus.
  ///
  /// Snapshot dari cache lokal tidak dipercaya: setelah diputus lalu
  /// disambung lagi, cache masih menyimpan "dokumen tidak ada" dan listener
  /// baru menerimanya lebih dulu daripada dokumen baru dari server. Hanya
  /// jawaban server yang boleh memutus sesi.
  @visibleForTesting
  static bool shouldUnlinkChildDevice({
    required bool exists,
    required bool fromCache,
    required Object? role,
    required Object? deviceChildId,
    required String childId,
  }) {
    if (fromCache) return false;
    final stillChild = exists && role == 'child' && deviceChildId == childId;
    return !stillChild;
  }

  void _watchChildDevice(String familyId, String childId) {
    final db = _db;
    if (db == null) return;
    unawaited(_deviceSub?.cancel());
    final uid = _auth.uid ?? '';
    _deviceSub = db
        .collection('families')
        .doc(familyId)
        .collection('devices')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data();
            final unlink = shouldUnlinkChildDevice(
              exists: snapshot.exists,
              fromCache: snapshot.metadata.isFromCache,
              role: data?['role'],
              deviceChildId: data?['childId'],
              childId: childId,
            );
            if (unlink) _clear();
          },
          onError: (Object e) {
            debugPrint('Perangkat anak tidak lagi terhubung: $e');
            _clear();
          },
        );
  }

  @override
  void dispose() {
    unawaited(_deviceSub?.cancel());
    super.dispose();
  }
}
