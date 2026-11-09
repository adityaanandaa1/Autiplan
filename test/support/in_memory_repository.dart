import 'dart:async';

import 'package:autiplan/data/models/models.dart';
import 'package:autiplan/data/repository.dart';

/// Repositori tes tanpa Firebase: menyimpan state di memori dan
/// memancarkannya lewat [watch].
class InMemoryRepository implements AutiPlanRepository {
  InMemoryRepository([AppState? initial]) : _current = initial;

  AppState? _current;
  final _updates = StreamController<AppState>.broadcast();

  /// Setiap pasangan (before, after) yang pernah dikirim ke [apply].
  final List<(AppState, AppState)> applied = [];

  /// Bila diisi, [apply] menunggu sampai future ini selesai.
  Completer<void>? applyGate;

  /// Bila diisi, [apply] gagal dengan galat ini.
  Object? applyError;

  /// Meniru perubahan dari HP lain.
  void emitRemote(AppState state) {
    _current = state;
    _updates.add(state);
  }

  @override
  Stream<AppState> watch() {
    late final StreamController<AppState> controller;
    StreamSubscription<AppState>? updates;
    controller = StreamController<AppState>(
      onListen: () {
        controller.add(_current ?? AppState.empty());
        updates = _updates.stream.listen(controller.add);
      },
      onCancel: () => updates?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<void> apply(AppState before, AppState after) async {
    applied.add((before, after));
    final error = applyError;
    if (error != null) throw error;
    final gate = applyGate;
    if (gate != null) await gate.future;
    _current = after;
    _updates.add(after);
  }
}
