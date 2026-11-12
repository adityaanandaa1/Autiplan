import 'package:autiplan/data/session/session_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

bool _unlink({
  required bool exists,
  required bool fromCache,
  Object? role,
  Object? deviceChildId,
  String childId = 'c1',
}) => SessionNotifier.shouldUnlinkChildDevice(
  exists: exists,
  fromCache: fromCache,
  role: role,
  deviceChildId: deviceChildId,
  childId: childId,
);

void main() {
  group('shouldUnlinkChildDevice', () {
    test('dokumen dari server masih milik anak ini: tetap terhubung', () {
      expect(
        _unlink(
          exists: true,
          fromCache: false,
          role: 'child',
          deviceChildId: 'c1',
        ),
        isFalse,
      );
    });

    test('server melaporkan dokumen hilang: putus', () {
      expect(_unlink(exists: false, fromCache: false), isTrue);
    });

    test('server melaporkan dokumen untuk anak lain: putus', () {
      expect(
        _unlink(
          exists: true,
          fromCache: false,
          role: 'child',
          deviceChildId: 'c2',
        ),
        isTrue,
      );
    });

    test('server melaporkan peran bukan child: putus', () {
      expect(
        _unlink(
          exists: true,
          fromCache: false,
          role: 'caregiver',
          deviceChildId: 'c1',
        ),
        isTrue,
      );
    });

    // Regresi: setelah diputus lalu disambung lagi, cache lokal masih
    // mengingat "dokumen tidak ada". Snapshot pertama listener baru berasal
    // dari cache itu dan tidak boleh memutus sesi yang baru dibuat.
    test('snapshot cache "tidak ada" tidak memutus sesi baru', () {
      expect(_unlink(exists: false, fromCache: true), isFalse);
    });

    test('snapshot cache yang basi (anak lain) tidak memutus sesi baru', () {
      expect(
        _unlink(
          exists: true,
          fromCache: true,
          role: 'child',
          deviceChildId: 'c2',
        ),
        isFalse,
      );
    });
  });
}
