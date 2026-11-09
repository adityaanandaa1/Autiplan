import 'package:autiplan/core/router.dart';
import 'package:autiplan/data/session/device_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const unlinked = UnlinkedSession();
  const caregiverNoChild = CaregiverSession(familyId: 'uid');
  const caregiverWithChild = CaregiverSession(familyId: 'uid');
  const child = ChildSession(familyId: 'f', childId: 'c');

  group('UnlinkedSession', () {
    for (final allowed in ['/mulai', '/masuk', '/daftar', '/hubungkan']) {
      test('$allowed → null (tetap)', () {
        expect(
          redirectFor(unlinked, path: allowed, hasChildren: false),
          isNull,
        );
      });
    }

    for (final blocked in ['/', '/profil-awal', '/ortu/beranda', '/anak']) {
      test('$blocked → /mulai', () {
        expect(
          redirectFor(unlinked, path: blocked, hasChildren: false),
          '/mulai',
        );
      });
    }
  });

  group('CaregiverSession tanpa anak', () {
    test('/profil-awal → null (tetap)', () {
      expect(
        redirectFor(caregiverNoChild, path: '/profil-awal', hasChildren: false),
        isNull,
      );
    });

    for (final blocked in [
      '/',
      '/mulai',
      '/masuk',
      '/daftar',
      '/hubungkan',
      '/ortu/beranda',
      '/anak',
    ]) {
      test('$blocked → /profil-awal', () {
        expect(
          redirectFor(caregiverNoChild, path: blocked, hasChildren: false),
          '/profil-awal',
        );
      });
    }
  });

  group('CaregiverSession dengan anak', () {
    for (final blocked in [
      '/',
      '/mulai',
      '/masuk',
      '/daftar',
      '/hubungkan',
      '/profil-awal',
      '/anak',
      '/anak/perubahan',
      '/anak/aktivitas/a',
      '/anak/tema',
    ]) {
      test('$blocked → /ortu/beranda', () {
        expect(
          redirectFor(caregiverWithChild, path: blocked, hasChildren: true),
          '/ortu/beranda',
        );
      });
    }

    for (final allowed in [
      '/ortu/beranda',
      '/ortu/jadwal',
      '/ortu/akun',
      '/ortu/notifikasi',
      '/ortu/saran',
    ]) {
      test('$allowed → null (tetap)', () {
        expect(
          redirectFor(caregiverWithChild, path: allowed, hasChildren: true),
          isNull,
        );
      });
    }
  });

  group('ChildSession', () {
    for (final allowed in [
      '/anak',
      '/anak/perubahan',
      '/anak/aktivitas/a',
      '/anak/berhasil/a',
      '/anak/darurat',
      '/anak/menelepon',
      '/anak/tema',
    ]) {
      test('$allowed → null (tetap)', () {
        expect(redirectFor(child, path: allowed, hasChildren: false), isNull);
        expect(redirectFor(child, path: allowed, hasChildren: true), isNull);
      });
    }

    for (final blocked in [
      '/',
      '/mulai',
      '/masuk',
      '/daftar',
      '/hubungkan',
      '/profil-awal',
      '/ortu/beranda',
    ]) {
      test('$blocked → /anak', () {
        expect(redirectFor(child, path: blocked, hasChildren: false), '/anak');
        expect(redirectFor(child, path: blocked, hasChildren: true), '/anak');
      });
    }
  });
}
