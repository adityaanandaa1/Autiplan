import 'dart:async';
import 'dart:convert';
// dart:io dipertahankan: SocketException/HandshakeException tidak selalu
// dibungkus http.ClientException oleh klien IO.
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PairingCode {
  const PairingCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

class ClaimedLink {
  const ClaimedLink({required this.familyId, required this.childId});

  final String familyId;
  final String childId;
}

enum BackendFailure {
  invalidCode,
  expiredCode,
  tooManyAttempts,
  offline,
  unknown,
}

class BackendException implements Exception {
  const BackendException(this.failure);

  final BackendFailure failure;

  @override
  String toString() => 'BackendException($failure)';
}

abstract class BackendApi {
  Future<PairingCode> createPairingCode(String childId);
  Future<ClaimedLink> claimPairingCode(String code);
  Future<void> notify(String familyId, String notificationId);
}

/// Implementasi [BackendApi] lewat HTTP ke Worker Cloudflare.
class HttpBackendApi implements BackendApi {
  HttpBackendApi({
    required this.baseUrl,
    required this.authService,
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 10);

  final String baseUrl;
  final AuthService authService;
  final http.Client _client;

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    final json = await _postJson('/pairing/create', {'childId': childId});
    return _parse(
      () => PairingCode(
        code: json['code'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      ),
    );
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    final json = await _postJson('/pairing/claim', {
      'code': code,
    }, badRequest: BackendFailure.invalidCode);
    return _parse(
      () => ClaimedLink(
        familyId: json['familyId'] as String,
        childId: json['childId'] as String,
      ),
    );
  }

  @override
  Future<void> notify(String familyId, String notificationId) async {
    await _post('/notify', {
      'familyId': familyId,
      'notificationId': notificationId,
    });
  }

  /// Body 2xx yang rusak atau salah bentuk menjadi [BackendFailure.unknown].
  static T _parse<T>(T Function() build) {
    try {
      return build();
    } on Object {
      throw const BackendException(BackendFailure.unknown);
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    BackendFailure badRequest = BackendFailure.unknown,
  }) async {
    final response = await _post(path, body, badRequest: badRequest);
    return _parse(() => jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    BackendFailure badRequest = BackendFailure.unknown,
  }) async {
    try {
      final token = await authService.idToken();
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw BackendException(_mapStatusCode(response.statusCode, badRequest));
    } on BackendException {
      rethrow;
    } on TimeoutException {
      throw const BackendException(BackendFailure.offline);
    } on SocketException {
      throw const BackendException(BackendFailure.offline);
    } on HandshakeException {
      throw const BackendException(BackendFailure.offline);
    } on http.ClientException {
      throw const BackendException(BackendFailure.offline);
    } on Object {
      // Galat auth (mis. gagal menyegarkan token) atau galat tak terduga.
      throw const BackendException(BackendFailure.unknown);
    }
  }

  static BackendFailure _mapStatusCode(int statusCode, BackendFailure bad) {
    return switch (statusCode) {
      400 => bad,
      410 => BackendFailure.expiredCode,
      429 => BackendFailure.tooManyAttempts,
      _ => BackendFailure.unknown,
    };
  }
}
