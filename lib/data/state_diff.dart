import 'models/models.dart';

/// Jenis penulisan satu dokumen.
enum DocOp { set, update, delete }

/// Satu penulisan dokumen Firestore, tanpa tergantung pada paket Firebase
/// supaya selisih state bisa dites sebagai fungsi murni.
///
/// [collection] dan [id] sama-sama null berarti dokumen keluarga
/// (`families/{familyId}`, berisi `Settings`).
class DocWrite {
  const DocWrite({
    this.collection,
    this.id,
    required this.op,
    this.fields = const {},
    this.deletedFields = const [],
  });

  final String? collection;
  final String? id;
  final DocOp op;

  /// `set`: seluruh isi dokumen. `update`: hanya kunci yang berubah.
  final Map<String, dynamic> fields;

  /// Kunci yang ada di dokumen lama dan hilang dari yang baru (mis. `end`).
  final List<String> deletedFields;

  @override
  String toString() =>
      'DocWrite($collection/$id, $op, $fields, deleted: $deletedFields)';
}

/// ID dokumen Completion: satu per kegiatan per tanggal.
String completionDocId(Completion c) {
  final d = c.date;
  return '${c.activityId}_${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Selisih [before] -> [after] sebagai penulisan per dokumen dan per field.
///
/// Dokumen baru `set`, yang hilang `delete`, yang berubah `update` berisi
/// hanya kunci yang berubah. Dua HP yang mengubah field berbeda pada
/// dokumen yang sama tidak saling menimpa.
List<DocWrite> diffAppState(AppState before, AppState after) {
  return [
    ..._diffDocs(
      'children',
      {for (final c in before.children) c.id: c.toJson()},
      {for (final c in after.children) c.id: c.toJson()},
    ),
    ..._diffDocs(
      'activities',
      {for (final a in before.activities) a.id: a.toJson()},
      {for (final a in after.activities) a.id: a.toJson()},
    ),
    ..._diffDocs(
      'completions',
      {for (final c in before.completions) completionDocId(c): c.toJson()},
      {for (final c in after.completions) completionDocId(c): c.toJson()},
    ),
    ..._diffDocs(
      'notices',
      {for (final n in before.notices) n.id: n.toJson()},
      {for (final n in after.notices) n.id: n.toJson()},
    ),
    ..._diffDocs(
      'notifications',
      {for (final n in before.notifications) n.id: n.toJson()},
      {for (final n in after.notifications) n.id: n.toJson()},
    ),
    ..._diffDocs(
      'suggestionStatus',
      {
        for (final e in before.suggestionStatus.entries)
          e.key: {'status': e.value.name},
      },
      {
        for (final e in after.suggestionStatus.entries)
          e.key: {'status': e.value.name},
      },
    ),
    ..._diffFamily(before.settings, after.settings),
  ];
}

List<DocWrite> _diffFamily(Settings before, Settings after) {
  final change = _diffFields(before.toJson(), after.toJson());
  if (change == null) return const [];
  return [
    DocWrite(
      op: DocOp.update,
      fields: change.changed,
      deletedFields: change.removed,
    ),
  ];
}

List<DocWrite> _diffDocs(
  String collection,
  Map<String, Map<String, dynamic>> before,
  Map<String, Map<String, dynamic>> after,
) {
  final writes = <DocWrite>[];
  for (final entry in after.entries) {
    final old = before[entry.key];
    if (old == null) {
      writes.add(
        DocWrite(
          collection: collection,
          id: entry.key,
          op: DocOp.set,
          fields: entry.value,
        ),
      );
      continue;
    }
    final change = _diffFields(old, entry.value);
    if (change != null) {
      writes.add(
        DocWrite(
          collection: collection,
          id: entry.key,
          op: DocOp.update,
          fields: change.changed,
          deletedFields: change.removed,
        ),
      );
    }
  }
  for (final id in before.keys) {
    if (!after.containsKey(id)) {
      writes.add(DocWrite(collection: collection, id: id, op: DocOp.delete));
    }
  }
  return writes;
}

({Map<String, dynamic> changed, List<String> removed})? _diffFields(
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) {
  final changed = <String, dynamic>{};
  for (final entry in after.entries) {
    if (!before.containsKey(entry.key) ||
        !_deepEquals(before[entry.key], entry.value)) {
      changed[entry.key] = entry.value;
    }
  }
  final removed = [
    for (final key in before.keys)
      if (!after.containsKey(key)) key,
  ];
  if (changed.isEmpty && removed.isEmpty) return null;
  return (changed: changed, removed: removed);
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
