import 'package:autiplan/data/firestore_repository.dart';
import 'package:autiplan/data/models/models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_state.dart';

const _family = 'fam-1';

/// Memberi event queue kesempatan menjalankan snapshot yang tertunda.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<Activity> _byDateThenStart(List<Activity> list) {
  final sorted = [...list];
  sorted.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byStart = a.start.toMinutes().compareTo(b.start.toMinutes());
    return byStart != 0 ? byStart : a.id.compareTo(b.id);
  });
  return sorted;
}

void main() {
  late FakeFirebaseFirestore db;
  late AppState base;

  setUp(() {
    db = FakeFirebaseFirestore();
    // Fixture bawaan tidak punya notice dan status saran; tambahkan supaya
    // semua koleksi ikut teruji.
    base = buildFixtureState().copyWith(
      notices: [
        ChangeNotice(
          id: 'notice-1',
          childId: 'child-rafi',
          activityId: 'act-x',
          before: const ActivitySnapshot(
            shortTitle: 'Les',
            title: 'Les',
            icon: ActivityIcon.sepeda,
            start: TimeOfDayLite(16, 0),
          ),
          message: 'Jam berubah.',
          sentAt: DateTime(2026, 5, 1, 9),
        ),
      ],
      suggestionStatus: {'s1': SuggestionStatus.dismissed},
    );
  });

  FirestoreRepository newRepo([String family = _family]) =>
      FirestoreRepository(db, family);

  Future<AppState> readOnce(FirestoreRepository repo) => repo.watch().first;

  test('AppState -> apply -> watch menghasilkan state setara', () async {
    final repo = newRepo();
    await repo.apply(AppState.empty(), base);

    final loaded = await readOnce(repo);

    expect(loaded.activities, _byDateThenStart(base.activities));
    expect(loaded.children, unorderedEquals(base.children));
    expect(loaded.completions, unorderedEquals(base.completions));
    expect(loaded.notices, unorderedEquals(base.notices));
    expect(loaded.notifications, unorderedEquals(base.notifications));
    expect(loaded.suggestionStatus, base.suggestionStatus);
    expect(loaded.settings, base.settings);
  });

  test('keluarga baru tanpa dokumen terbaca sebagai state kosong', () async {
    final loaded = await readOnce(newRepo());
    expect(loaded, AppState.empty());
  });

  test('keluarga lain tidak terpengaruh', () async {
    await newRepo().apply(AppState.empty(), base);
    final other = await readOnce(newRepo('fam-lain'));
    expect(other, AppState.empty());
  });

  test('dua HP: perubahan keduanya tetap ada', () async {
    final a = newRepo();
    final b = newRepo();
    await a.apply(AppState.empty(), base);

    final target = base.activities.firstWhere((x) => x.steps.isNotEmpty);
    final titleChanged = base.copyWith(
      activities: [
        for (final x in base.activities)
          x.id == target.id ? x.copyWith(title: 'Judul dari orang tua') : x,
      ],
    );
    final completion = Completion(
      activityId: target.id,
      date: target.date,
      completedAt: DateTime(2026, 5, 1, 10),
      onTime: true,
      stepsChecked: const [true],
    );
    final fromOldState = base.copyWith(
      activities: [
        for (final x in base.activities)
          x.id == target.id ? x.copyWith(steps: ['Langkah baru']) : x,
      ],
      completions: [...base.completions, completion],
    );

    await a.apply(base, titleChanged);
    await b.apply(base, fromOldState);

    final merged = await readOnce(newRepo());
    final result = merged.activities.firstWhere((x) => x.id == target.id);
    expect(result.title, 'Judul dari orang tua');
    expect(result.steps, ['Langkah baru']);
    expect(merged.completions.any((c) => c.activityId == target.id), isTrue);
  });

  test('watch beremisi sekali setelah semua koleksi punya snapshot', () async {
    await newRepo().apply(AppState.empty(), base);

    final emissions = <AppState>[];
    final sub = newRepo().watch().listen(emissions.add);
    await _settle();
    await sub.cancel();

    expect(emissions, hasLength(1));
    final first = emissions.single;
    expect(first.children, isNotEmpty);
    expect(first.activities, isNotEmpty);
    expect(first.completions, isNotEmpty);
    expect(first.notices, isNotEmpty);
    expect(first.settings, base.settings);
  });

  test('watch memancarkan perubahan berikutnya', () async {
    final repo = newRepo();
    await repo.apply(AppState.empty(), base);

    final emissions = <AppState>[];
    final sub = repo.watch().listen(emissions.add);
    await _settle();

    final removed = base.copyWith(activities: base.activities.skip(1).toList());
    await repo.apply(base, removed);
    await _settle();
    await sub.cancel();

    expect(emissions.last.activities.length, base.activities.length - 1);
  });

  test('mengubah Settings tersimpan di dokumen keluarga', () async {
    final repo = newRepo();
    await repo.apply(AppState.empty(), base);
    final changed = base.copyWith(
      settings: base.settings.copyWith(caregiverName: 'Nama Baru'),
    );
    await repo.apply(base, changed);

    final snapshot = await db.collection('families').doc(_family).get();
    expect(snapshot.data()!['caregiverName'], 'Nama Baru');
  });

  test('field yang dihapus ikut terhapus di dokumen', () async {
    final repo = newRepo();
    await repo.apply(AppState.empty(), base);
    final target = base.activities.firstWhere((x) => x.end != null);
    final changed = base.copyWith(
      activities: [
        for (final x in base.activities)
          x.id == target.id ? x.copyWith(clearEnd: true) : x,
      ],
    );
    await repo.apply(base, changed);

    final doc = await db
        .collection('families')
        .doc(_family)
        .collection('activities')
        .doc(target.id)
        .get();
    expect(doc.data()!.containsKey('end'), isFalse);
  });

  test('lebih dari 450 operasi dipecah menjadi beberapa batch', () async {
    final repo = newRepo();
    final many = [
      for (var i = 0; i < 1000; i++)
        base.activities.first.copyWith(id: 'bulk-$i'),
    ];
    await repo.apply(
      AppState.empty(),
      AppState.empty().copyWith(activities: many),
    );

    final loaded = await readOnce(repo);
    expect(loaded.activities, hasLength(1000));
  });

  test('dokumen yang rusak dilewati, yang lain tetap terbaca', () async {
    final repo = newRepo();
    await repo.apply(AppState.empty(), base);
    await db
        .collection('families')
        .doc(_family)
        .collection('activities')
        .doc('rusak')
        .set({'id': 'rusak', 'title': 123});

    final loaded = await readOnce(repo);
    expect(loaded.activities.any((a) => a.id == 'rusak'), isFalse);
    expect(loaded.activities, hasLength(base.activities.length));
  });
}
