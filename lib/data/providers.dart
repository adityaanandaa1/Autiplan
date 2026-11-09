import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../domain/recurrence.dart';
import 'auth_service.dart';
import 'firestore_repository.dart';
import 'models/models.dart';
import 'repository.dart';
import 'session/device_session.dart';
import 'session/session_notifier.dart';

/// Provider for SharedPreferences instance. Must be overridden in main().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Layanan autentikasi. Harus di-override di main() (atau di tes).
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('authServiceProvider must be overridden');
});

/// Notifier sesi perangkat; [sessionProvider] hanyalah pembacanya.
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, DeviceSession>((ref) {
      return SessionNotifier(
        ref.watch(authServiceProvider),
        ref.watch(sharedPreferencesProvider),
        db: fs.FirebaseFirestore.instance,
      );
    });

/// Sesi perangkat saat ini (belum masuk, orang tua, atau anak).
final sessionProvider = Provider<DeviceSession>((ref) {
  return ref.watch(sessionNotifierProvider);
});

/// Repositori untuk sesi tanpa keluarga (belum masuk): tidak membaca atau
/// menulis apa pun, supaya layar onboarding tidak butuh data.
class _UnlinkedRepository implements AutiPlanRepository {
  const _UnlinkedRepository();

  @override
  Stream<AppState> watch() => Stream<AppState>.value(AppState.empty());

  @override
  Future<void> apply(AppState before, AppState after) async {}
}

/// Sumber data aplikasi, dibuat dari sesi: `familyId` = uid orang tua, atau
/// `familyId` dari [ChildSession]. Dibuat ulang saat sesi berubah.
final repositoryProvider = Provider<AutiPlanRepository>((ref) {
  final session = ref.watch(sessionProvider);
  return switch (session) {
    CaregiverSession(:final familyId) || ChildSession(:final familyId) =>
      FirestoreRepository(fs.FirebaseFirestore.instance, familyId),
    UnlinkedSession() => const _UnlinkedRepository(),
  };
});

/// StateNotifier for managing the global AppState.
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier(
    this._repository,
    AppState initial, {
    AppState Function(AppState)? normalize,
  }) : _normalize = normalize,
       super(normalize == null ? initial : normalize(initial));

  final AutiPlanRepository _repository;

  /// Dipakai pada setiap perubahan, mis. memperluas kegiatan berulang.
  final AppState Function(AppState)? _normalize;

  StreamSubscription<AppState>? _subscription;
  Completer<void>? _ready;

  /// Selesai setelah emisi pertama [AutiPlanRepository.watch] (atau galat
  /// pertamanya, supaya layar tidak menggantung). Langsung selesai bila
  /// [start] tidak pernah dipanggil.
  Future<void> get ready => _ready?.future ?? Future<void>.value();

  /// Mulai mengikuti repositori. Aman dipanggil lebih dari sekali.
  void start() {
    if (_subscription != null) return;
    final ready = _ready = Completer<void>();
    _subscription = _repository.watch().listen(
      (remote) {
        if (!mounted) return;
        state = remote;
        renormalize();
        if (!ready.isCompleted) ready.complete();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Data tidak bisa dimuat: $error');
        if (!ready.isCompleted) ready.complete();
      },
    );
  }

  /// Ubah state seketika, lalu tulis selisihnya ke repositori tanpa
  /// menunggu: tanpa internet, penulisan baru selesai saat HP online lagi.
  void updateState(AppState newState) {
    final next = _normalize == null ? newState : _normalize(newState);
    final before = state;
    state = next;
    unawaited(
      Future<void>.sync(() => _repository.apply(before, next)).catchError((
        Object error,
        StackTrace stack,
      ) {
        debugPrint('Perubahan belum tersimpan: $error');
      }),
    );
  }

  /// Menormalkan ulang state sekarang, mis. saat hari berganti.
  void renormalize() {
    final normalize = _normalize;
    if (normalize == null) return;
    final next = normalize(state);
    if (identical(next.activities, state.activities)) return;
    updateState(next);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}

/// Provider for AppStateNotifier.
///
/// `normalize` (perluasan kegiatan berulang) hanya dipasang di HP orang tua;
/// HP anak tidak boleh menulis kegiatan yang dibuat ulang.
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((
  ref,
) {
  final session = ref.watch(sessionProvider);
  final AppState Function(AppState)? normalize = switch (session) {
    CaregiverSession() => (s) => s.copyWith(
      activities: materializeRecurring(
        s.activities,
        ref.read(clockProvider).now,
      ),
    ),
    _ => null,
  };
  final notifier = AppStateNotifier(
    ref.watch(repositoryProvider),
    AppState.empty(),
    normalize: normalize,
  );
  // Hari berganti: perluas seri berulang tanpa menunggu perubahan lain.
  ref.listen<DateTime>(currentDayProvider, (_, _) => notifier.renormalize());
  notifier.start();
  return notifier;
});

/// Selesai setelah data pertama dimuat dari repositori.
final repositoryReadyProvider = FutureProvider<void>((ref) {
  return ref.watch(appStateProvider.notifier).ready;
});

/// Provider for the currently selected child ID in caregiver view.
final selectedChildIdProvider = StateProvider<String?>((ref) => null);

/// Anak yang sedang dipakai: anak terpilih, atau anak pertama, atau null.
///
/// Di HP anak, anak dipilih dari [ChildSession.childId].
final currentChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(appStateProvider.select((s) => s.children));
  if (children.isEmpty) return null;

  final session = ref.watch(sessionProvider);
  if (session is ChildSession) {
    for (final child in children) {
      if (child.id == session.childId) return child;
    }
    return null;
  }

  final selectedId = ref.watch(selectedChildIdProvider);
  if (selectedId != null) {
    for (final child in children) {
      if (child.id == selectedId) return child;
    }
  }
  return children.first;
});
