import 'dart:io';

import 'package:autiplan/data/backend_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fake_auth_service.dart';

void main() {
  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService();
  });

  group('HttpBackendApi error mapping', () {
    test('400 → invalidCode', () async {
      final client = MockClient(
        (req) async => http.Response('{"error":"invalid_code"}', 400),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      expect(
        () => api.claimPairingCode('123456'),
        throwsA(
          isA<BackendException>().having(
            (e) => e.failure,
            'failure',
            BackendFailure.invalidCode,
          ),
        ),
      );
    });

    test('410 → expiredCode', () async {
      final client = MockClient(
        (req) async => http.Response('{"error":"expired_code"}', 410),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      expect(
        () => api.claimPairingCode('123456'),
        throwsA(
          isA<BackendException>().having(
            (e) => e.failure,
            'failure',
            BackendFailure.expiredCode,
          ),
        ),
      );
    });

    test('429 → tooManyAttempts', () async {
      final client = MockClient(
        (req) async => http.Response('{"error":"too_many_attempts"}', 429),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      expect(
        () => api.claimPairingCode('123456'),
        throwsA(
          isA<BackendException>().having(
            (e) => e.failure,
            'failure',
            BackendFailure.tooManyAttempts,
          ),
        ),
      );
    });

    test('SocketException → offline', () async {
      final client = MockClient(
        (req) async => throw const SocketException('No net'),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      expect(
        () => api.claimPairingCode('123456'),
        throwsA(
          isA<BackendException>().having(
            (e) => e.failure,
            'failure',
            BackendFailure.offline,
          ),
        ),
      );
    });

    test('500 → unknown', () async {
      final client = MockClient(
        (req) async => http.Response('{"error":"server_error"}', 500),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      expect(
        () => api.claimPairingCode('123456'),
        throwsA(
          isA<BackendException>().having(
            (e) => e.failure,
            'failure',
            BackendFailure.unknown,
          ),
        ),
      );
    });
  });

  group('HttpBackendApi suksek', () {
    test('createPairingCode mengembalikan PairingCode', () async {
      final client = MockClient(
        (req) async => http.Response(
          '{"code":"654321","expiresAt":"2026-11-10T12:10:00Z"}',
          200,
        ),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      final result = await api.createPairingCode('child-1');
      expect(result.code, '654321');
      expect(result.expiresAt, DateTime.parse('2026-11-10T12:10:00Z'));
    });

    test('claimPairingCode mengembalikan ClaimedLink', () async {
      final client = MockClient(
        (req) async =>
            http.Response('{"familyId":"fam-123","childId":"child-1"}', 200),
      );
      final api = HttpBackendApi(
        baseUrl: 'https://test.worker',
        authService: auth,
        client: client,
      );

      final result = await api.claimPairingCode('654321');
      expect(result.familyId, 'fam-123');
      expect(result.childId, 'child-1');
    });
  });
}
