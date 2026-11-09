import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/state_diff.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_state.dart';

void main() {
  late AppState base;

  setUp(() => base = buildFixtureState());

  Activity firstActivity(AppState s) => s.activities.first;

  List<Activity> replaceFirst(AppState s, Activity a) => [
    a,
    ...s.activities.skip(1),
  ];

  group('diffAppState', () {
    test('state yang sama tidak menulis apa pun', () {
      expect(diffAppState(base, base), isEmpty);
    });

    test('mengubah title satu kegiatan -> satu update hanya berisi title', () {
      final changed = firstActivity(base).copyWith(title: 'Judul baru');
      final writes = diffAppState(
        base,
        base.copyWith(activities: replaceFirst(base, changed)),
      );
      expect(writes, hasLength(1));
      expect(writes.single.collection, 'activities');
      expect(writes.single.id, changed.id);
      expect(writes.single.op, DocOp.update);
      expect(writes.single.fields, {'title': 'Judul baru'});
      expect(writes.single.deletedFields, isEmpty);
    });

    test('kegiatan baru -> set dengan seluruh isi', () {
      final added = firstActivity(base).copyWith(id: 'act-baru');
      final writes = diffAppState(
        base,
        base.copyWith(activities: [...base.activities, added]),
      );
      expect(writes, hasLength(1));
      expect(writes.single.op, DocOp.set);
      expect(writes.single.id, 'act-baru');
      expect(writes.single.fields, added.toJson());
    });

    test('kegiatan dihapus -> delete', () {
      final writes = diffAppState(
        base,
        base.copyWith(activities: base.activities.skip(1).toList()),
      );
      expect(writes, hasLength(1));
      expect(writes.single.op, DocOp.delete);
      expect(writes.single.collection, 'activities');
      expect(writes.single.id, firstActivity(base).id);
    });

    test('kunci yang hilang dari JSON dicatat di deletedFields', () {
      final withEnd = firstActivity(base);
      expect(withEnd.end, isNotNull);
      final writes = diffAppState(
        base,
        base.copyWith(
          activities: replaceFirst(base, withEnd.copyWith(clearEnd: true)),
        ),
      );
      expect(writes.single.op, DocOp.update);
      expect(writes.single.fields, isEmpty);
      expect(writes.single.deletedFields, ['end']);
    });

    test('nilai bersarang yang sama tidak dianggap berubah', () {
      final copy = AppState.fromJson(base.toJson());
      expect(diffAppState(base, copy), isEmpty);
    });

    test('Completion memakai completionDocId', () {
      final completion = Completion(
        activityId: 'act-1',
        date: DateTime(2026, 5, 1),
        completedAt: DateTime(2026, 5, 1, 10),
        onTime: true,
        stepsChecked: const [true],
      );
      expect(completionDocId(completion), 'act-1_2026-05-01');

      final added = base.copyWith(
        completions: [...base.completions, completion],
      );
      final addWrites = diffAppState(base, added);
      expect(addWrites.single.collection, 'completions');
      expect(addWrites.single.id, 'act-1_2026-05-01');
      expect(addWrites.single.op, DocOp.set);

      final removeWrites = diffAppState(added, base);
      expect(removeWrites.single.op, DocOp.delete);
      expect(removeWrites.single.id, 'act-1_2026-05-01');

      final late = completion.copyWith(onTime: false);
      final updateWrites = diffAppState(
        added,
        added.copyWith(completions: [...base.completions, late]),
      );
      expect(updateWrites.single.op, DocOp.update);
      expect(updateWrites.single.fields, {'onTime': false});
    });

    test('mengubah Settings -> dokumen keluarga (collection null)', () {
      final writes = diffAppState(
        base,
        base.copyWith(settings: base.settings.copyWith(minGapMinutes: 25)),
      );
      expect(writes, hasLength(1));
      expect(writes.single.collection, isNull);
      expect(writes.single.id, isNull);
      expect(writes.single.op, DocOp.update);
      expect(writes.single.fields, {'minGapMinutes': 25});
    });

    test('status saran: baru -> set {status}, berubah -> update', () {
      final first = base.copyWith(
        suggestionStatus: {'s1': SuggestionStatus.dismissed},
      );
      final set = diffAppState(
        base.copyWith(suggestionStatus: {}),
        first,
      ).single;
      expect(set.collection, 'suggestionStatus');
      expect(set.id, 's1');
      expect(set.op, DocOp.set);
      expect(set.fields, {'status': 'dismissed'});

      final update = diffAppState(
        first,
        first.copyWith(suggestionStatus: {'s1': SuggestionStatus.applied}),
      ).single;
      expect(update.op, DocOp.update);
      expect(update.fields, {'status': 'applied'});
    });

    test('notice dan notifikasi baru masuk koleksinya masing-masing', () {
      final notification = CaregiverNotification(
        id: 'n-baru',
        type: NotificationType.emergencyPressed,
        text: 'x',
        at: DateTime(2026, 5, 1),
        read: false,
      );
      final writes = diffAppState(
        base,
        base.copyWith(notifications: [...base.notifications, notification]),
      );
      expect(writes.single.collection, 'notifications');
      expect(writes.single.id, 'n-baru');
    });
  });
}
