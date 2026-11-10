import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

abstract class PushService {
  Future<void> registerCaregiverDevice(String familyId);

  /// Membatalkan pendaftaran push (dipanggil saat keluar). Tidak pernah melempar.
  Future<void> unregister();
}

class FirebasePushService implements PushService {
  FirebasePushService({this.messaging, this.firestore, this.auth});

  final FirebaseMessaging? messaging;
  final FirebaseFirestore? firestore;
  final fa.FirebaseAuth? auth;

  StreamSubscription<String>? _refresh;
  String? _familyId;
  String? _uid;

  @override
  Future<void> registerCaregiverDevice(String familyId) async {
    try {
      final messenger = messaging ?? FirebaseMessaging.instance;
      final settings = await messenger.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final uid = (auth ?? fa.FirebaseAuth.instance).currentUser?.uid;
      if (uid == null) return;

      // ignore: deprecated_member_use
      final token = await messenger.getToken();
      if (token == null || token.isEmpty) return;

      await _saveToken(familyId, uid, token);

      // Ganti langganan lama (mis. keluarga berbeda); panggilan ulang untuk
      // keluarga yang sama hanya memasang satu langganan.
      await _refresh?.cancel();
      _familyId = familyId;
      _uid = uid;
      // ignore: deprecated_member_use
      _refresh = messenger.onTokenRefresh.listen((next) {
        _saveToken(familyId, uid, next).catchError((Object e) {
          debugPrint('Gagal menyimpan token push: $e');
        });
      });
    } on Exception catch (e) {
      // FirebaseException juga turunan Exception.
      debugPrint('Push orang tua tidak aktif: $e');
    }
  }

  @override
  Future<void> unregister() async {
    final familyId = _familyId;
    final uid = _uid;
    final refresh = _refresh;
    _familyId = null;
    _uid = null;
    _refresh = null;
    try {
      await refresh?.cancel();
      if (familyId != null && uid != null) {
        final db = firestore ?? FirebaseFirestore.instance;
        await db
            .collection('families')
            .doc(familyId)
            .collection('devices')
            .doc(uid)
            .update({'fcmToken': FieldValue.delete()});
      }
    } on Exception catch (e) {
      debugPrint('Gagal menghapus token push: $e');
    }
    try {
      // ignore: deprecated_member_use
      await (messaging ?? FirebaseMessaging.instance).deleteToken();
    } on Exception catch (e) {
      debugPrint('Gagal menghapus token FCM: $e');
    }
  }

  Future<void> _saveToken(String familyId, String uid, String token) async {
    final db = firestore ?? FirebaseFirestore.instance;
    await db
        .collection('families')
        .doc(familyId)
        .collection('devices')
        .doc(uid)
        .set({'role': 'caregiver', 'fcmToken': token}, SetOptions(merge: true));
  }
}
