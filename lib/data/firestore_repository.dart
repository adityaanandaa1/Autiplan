import 'dart:async';
import 'dart:math' as math;

// Diimpor dengan "as fs" karena Settings milik Firestore bentrok dengan
// model Settings kita.
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';

import 'models/models.dart';
import 'repository.dart';
import 'state_diff.dart';

/// [AutiPlanRepository] di atas Firestore.
///
/// Struktur: `families/{familyId}` berisi `Settings`, dengan subkoleksi
/// `children`, `activities`, `completions`, `notices`, `notifications`, dan
/// `suggestionStatus`.
class FirestoreRepository implements AutiPlanRepository {
  FirestoreRepository(this._db, this._familyId);

  final fs.FirebaseFirestore _db;
  final String _familyId;

  /// Batas Firestore 500 operasi per batch; sisakan ruang.
  static const _batchLimit = 450;

  static const _familyKey = 'family';
  static const _collections = [
    'children',
    'activities',
    'completions',
    'notices',
    'notifications',
    'suggestionStatus',
  ];

  fs.DocumentReference<Map<String, dynamic>> get _family =>
      _db.collection('families').doc(_familyId);

  @override
  Stream<AppState> watch() {
    final latest = <String, Object>{};
    final subscriptions = <StreamSubscription<dynamic>>[];
    late final StreamController<AppState> controller;

    void onData(String key, Object snapshot) {
      latest[key] = snapshot;
      // Tunggu snapshot pertama dari semua sumber supaya tidak ada state
      // setengah jadi (mis. jadwal kosong) yang sempat tampil.
      if (latest.length == _collections.length + 1 && !controller.isClosed) {
        controller.add(_assemble(latest));
      }
    }

    controller = StreamController<AppState>(
      onListen: () {
        subscriptions.add(
          _family.snapshots().listen(
            (s) => onData(_familyKey, s),
            onError: controller.addError,
          ),
        );
        for (final name in _collections) {
          subscriptions.add(
            _family
                .collection(name)
                .snapshots()
                .listen((s) => onData(name, s), onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  AppState _assemble(Map<String, Object> latest) {
    final familyDoc =
        latest[_familyKey]! as fs.DocumentSnapshot<Map<String, dynamic>>;
    final familyData = familyDoc.data();
    final settings = familyData == null
        ? const Settings()
        : _parse('settings', familyData, Settings.fromJson) ?? const Settings();

    List<T> read<T>(String name, T Function(Map<String, dynamic>) fromJson) {
      final query = latest[name]! as fs.QuerySnapshot<Map<String, dynamic>>;
      final items = <T>[];
      for (final doc in query.docs) {
        final item = _parse(name, doc.data(), fromJson);
        if (item != null) items.add(item);
      }
      return items;
    }

    final statusQuery =
        latest['suggestionStatus']! as fs.QuerySnapshot<Map<String, dynamic>>;
    final statuses = <String, SuggestionStatus>{};
    for (final doc in statusQuery.docs) {
      final status = _parse(
        'suggestionStatus',
        doc.data(),
        (json) => SuggestionStatus.values.byName(json['status'] as String),
      );
      if (status != null) statuses[doc.id] = status;
    }

    final activities = read('activities', Activity.fromJson)
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        final byStart = a.start.toMinutes().compareTo(b.start.toMinutes());
        return byStart != 0 ? byStart : a.id.compareTo(b.id);
      });
    final notices = read('notices', ChangeNotice.fromJson)
      ..sort((a, b) {
        final bySent = a.sentAt.compareTo(b.sentAt);
        return bySent != 0 ? bySent : a.id.compareTo(b.id);
      });
    final notifications = read('notifications', CaregiverNotification.fromJson)
      ..sort((a, b) {
        final byTime = a.at.compareTo(b.at);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });

    return AppState(
      // Snapshot Firestore sudah berurutan menurut ID dokumen.
      children: read('children', Child.fromJson),
      activities: activities,
      completions: read('completions', Completion.fromJson),
      notices: notices,
      notifications: notifications,
      suggestionStatus: statuses,
      settings: settings,
    );
  }

  /// Satu dokumen rusak (mis. dari versi aplikasi lain) tidak boleh
  /// menjatuhkan seluruh jadwal; lewati dan catat.
  T? _parse<T>(
    String where,
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      return fromJson(json);
    } on TypeError catch (e) {
      debugPrint('Dokumen $where dilewati: $e');
    } on FormatException catch (e) {
      debugPrint('Dokumen $where dilewati: $e');
    } on ArgumentError catch (e) {
      debugPrint('Dokumen $where dilewati: $e');
    }
    return null;
  }

  @override
  Future<void> apply(AppState before, AppState after) {
    final writes = diffAppState(before, after);
    if (writes.isEmpty) return Future<void>.value();

    // Semua commit dikirim berurutan tanpa menunggu satu per satu, supaya
    // urutan tulis terjaga dan antrean offline tetap utuh.
    final commits = <Future<void>>[];
    for (var i = 0; i < writes.length; i += _batchLimit) {
      final batch = _db.batch();
      final end = math.min(i + _batchLimit, writes.length);
      for (final write in writes.sublist(i, end)) {
        _queue(batch, write);
      }
      commits.add(batch.commit());
    }
    return Future.wait(commits).then((_) {});
  }

  void _queue(fs.WriteBatch batch, DocWrite write) {
    final collection = write.collection;
    final id = write.id;
    if (collection == null || id == null) {
      // Dokumen keluarga mungkin belum ada pada penulisan pertama.
      batch.set(_family, _updateData(write), fs.SetOptions(merge: true));
      return;
    }
    final ref = _family.collection(collection).doc(id);
    switch (write.op) {
      case DocOp.set:
        batch.set(ref, write.fields);
      case DocOp.update:
        batch.update(ref, _updateData(write));
      case DocOp.delete:
        batch.delete(ref);
    }
  }

  Map<String, dynamic> _updateData(DocWrite write) => {
    ...write.fields,
    for (final key in write.deletedFields) key: fs.FieldValue.delete(),
  };

  @override
  Future<void> unlinkChildDevice(String childId) async {
    final query = await _family
        .collection('devices')
        .where('childId', isEqualTo: childId)
        .get();
    for (final doc in query.docs) {
      if (doc.data()['role'] == 'child') {
        await doc.reference.delete();
      }
    }
  }
}
