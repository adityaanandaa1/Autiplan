// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

abstract class PushService {
  Future<void> registerCaregiverDevice(String familyId);
}

class FirebasePushService implements PushService {
  FirebasePushService({this.messaging, this.firestore, this.auth});

  final FirebaseMessaging? messaging;
  final FirebaseFirestore? firestore;
  final fa.FirebaseAuth? auth;
  StreamSubscription<String>? _refresh;

  @override
  Future<void> registerCaregiverDevice(String familyId) async {
    try {
      final messenger = messaging ?? FirebaseMessaging.instance;
      final settings = await messenger.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final uid = (auth ?? fa.FirebaseAuth.instance).currentUser?.uid;
      if (uid == null) return;

      final token = await messenger.getToken();
      if (token == null || token.isEmpty) return;

      await _saveToken(familyId, uid, token);

      _refresh ??= messenger.onTokenRefresh.listen((next) {
        unawaited(_saveToken(familyId, uid, next));
      });
    } on FirebaseException catch (e) {
      debugPrint('Push orang tua tidak aktif: ${e.code}');
    } on Exception catch (e) {
      debugPrint('Push orang tua tidak aktif: $e');
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
