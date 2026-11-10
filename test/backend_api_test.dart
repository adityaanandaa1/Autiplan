import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autiplan/data/auth_service.dart';
import 'package:autiplan/data/backend_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_auth_service.dart';

class _NullTokenAuth extends FakeAuthService {
  @override
  Future<String?> idToken() async => null;
}

class _ThrowingAuth extends FakeAuthService {
  @override
  Future<String?> idToken() async => throw StateError('auth rusak');
}

void main() {
  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService();
  });

  HttpBackendApi apiFor(
    Future<http.Response> Function(http.Request) handler, {
    AuthService? authService,
  }) => HttpBackendApi(
    baseUrl: 'https://test.worker',
    authService: authService ?? auth,
    client: MockClient(handler),
  );

  Matcher failure(BackendFailure f) =>
      throwsA(isA<BackendException>().having((e) => e.failure, 'failure', f));

  group('kontrak request', () {
    test('createPairingCode', () async {
      late http.Request seen;
      final api = apiFor((req) async {
        seen = req;
        return http.Response(
          '{"code":"654321","expiresAt":"2026-11-10T12:10:00Z"}',
          200,
        );
      });

      final result = await api.createPairingCode('child-1');

      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'https://test.worker/pairing/create');
      expect(seen.headers['Authorization'], 'Bearer fake-token');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {'childId': 'child-1'});
      expect(result.code, '654321');
      expect(result.expiresAt, DateTime.parse('2026-11-10T12:10:00Z'));
    });

    test('claimPairingCode', () async {
      late http.Request seen;
      final api = apiFor((req) async {
        seen = req;
        return http.Response('{"familyId":"fam-123","childId":"child-1"}', 200);
      });

      final result = await api.claimPairingCode('654321');

      expect(seen.url.toString(), 'https://test.worker/pairing/claim');
      expect(seen.headers['Authorization'], 'Bearer fake-token');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {'code': '654321'});
      expect(result.familyId, 'fam-123');
      expect(result.childId, 'child-1');
    });

    test('notify', () async {
      late http.Request seen;
      final api = apiFor((req) async {
        seen = req;
        return http.Response('{}', 200);
      });

      await api.notify('fam-1', 'notif-1');

      expect(seen.url.toString(), 'https://test.worker/notify');
      expect(seen.headers['Authorization'], 'Bearer fake-token');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {
        'familyId': 'fam-1',
        'notificationId': 'notif-1',
      });
    });

    test('idToken null: tanpa header Authorization', () async {
      late http.Request seen;
      final api = apiFor((req) async {
        seen = req;
        return http.Response('{}', 200);
      }, authService: _NullTokenAuth());

      await api.notify('fam-1', 'notif-1');

      expect(seen.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('pemetaan galat', () {
    Future<http.Response> status(int code) async => http.Response('{}', code);

    test('claim: 400 jadi invalidCode', () async {
      await expectLater(
        apiFor((_) => status(400)).claimPairingCode('123456'),
        failure(BackendFailure.invalidCode),
      );
    });

    test('create dan notify: 400 jadi unknown', () async {
      final api = apiFor((_) => status(400));
      await expectLater(
        api.createPairingCode('c'),
        failure(BackendFailure.unknown),
      );
      await expectLater(api.notify('f', 'n'), failure(BackendFailure.unknown));
    });

    test('410 jadi expiredCode', () async {
      await expectLater(
        apiFor((_) => status(410)).claimPairingCode('123456'),
        failure(BackendFailure.expiredCode),
      );
    });

    test('429 jadi tooManyAttempts', () async {
      await expectLater(
        apiFor((_) => status(429)).claimPairingCode('123456'),
        failure(BackendFailure.tooManyAttempts),
      );
    });

    for (final code in [401, 403, 404, 500]) {
      test('$code jadi unknown', () async {
        await expectLater(
          apiFor((_) => status(code)).claimPairingCode('123456'),
          failure(BackendFailure.unknown),
        );
      });
    }

    final offlineCases = <String, Object>{
      'SocketException': const SocketException('No net'),
      'HandshakeException': const HandshakeException('tls'),
      'ClientException': http.ClientException('putus'),
      'TimeoutException': TimeoutException('lambat'),
    };
    offlineCases.forEach((name, error) {
      test('$name jadi offline', () async {
        await expectLater(
          apiFor((_) async => throw error).claimPairingCode('123456'),
          failure(BackendFailure.offline),
        );
      });
    });

    test('galat idToken jadi unknown, bukan galat mentah', () async {
      final api = apiFor(
        (_) async => http.Response('{}', 200),
        authService: _ThrowingAuth(),
      );
      await expectLater(
        api.claimPairingCode('123456'),
        failure(BackendFailure.unknown),
      );
    });

    test('body 2xx rusak jadi unknown', () async {
      final api = apiFor((_) async => http.Response('bukan json', 200));
      await expectLater(
        api.claimPairingCode('123456'),
        failure(BackendFailure.unknown),
      );
      await expectLater(
        api.createPairingCode('c'),
        failure(BackendFailure.unknown),
      );
    });

    test('body 2xx salah bentuk jadi unknown', () async {
      final api = apiFor((_) async => http.Response('{"familyId":1}', 200));
      await expectLater(
        api.claimPairingCode('123456'),
        failure(BackendFailure.unknown),
      );
    });
  });
}
