import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'firestore_repository.dart';
import 'repository.dart';

/// ID keluarga sementara sampai ada login (Tahap 10, saat `familyId` menjadi
/// `uid` orang tua). Aturan keamanan menolak semua akses sampai saat itu.
const pendingFamilyId = 'belum-masuk';

/// Menyalakan Firebase dan membuka repositori Firestore untuk [familyId].
Future<AutiPlanRepository> openFirestoreRepository(String familyId) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final db = fs.FirebaseFirestore.instance;
  db.settings = const fs.Settings(persistenceEnabled: true);
  return FirestoreRepository(db, familyId);
}
