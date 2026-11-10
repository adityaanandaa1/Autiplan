import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class PairingCode {
  const PairingCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairingCode &&
          code == other.code &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(code, expiresAt);
}

class ClaimedLink {
  const ClaimedLink({required this.familyId, required this.childId});

  final String familyId;
  final String childId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimedLink &&
          familyId == other.familyId &&
          childId == other.childId;

  @override
  int get hashCode => Object.hash(familyId, childId);
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

  final String baseUrl;
  final AuthService authService;
  final http.Client _client;

  @override
  Future<PairingCode> createPairingCode(String childId) async {
    final response = await _post('/pairing/create', {'childId': childId});
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PairingCode(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  Future<ClaimedLink> claimPairingCode(String code) async {
    final response = await _post('/pairing/claim', {'code': code});
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ClaimedLink(
      familyId: json['familyId'] as String,
      childId: json['childId'] as String,
    );
  }

  @override
  Future<void> notify(String familyId, String notificationId) async {
    await _post('/notify', {
      'familyId': familyId,
      'notificationId': notificationId,
    });
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final token = await authService.idToken();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw _mapStatusCode(response.statusCode);
    } on SocketException {
      throw const BackendException(BackendFailure.offline);
    } on http.ClientException {
      throw const BackendException(BackendFailure.offline);
    }
  }

  static BackendException _mapStatusCode(int statusCode) {
    return switch (statusCode) {
      400 => const BackendException(BackendFailure.invalidCode),
      410 => const BackendException(BackendFailure.expiredCode),
      429 => const BackendException(BackendFailure.tooManyAttempts),
      _ => const BackendException(BackendFailure.unknown),
    };
  }
}
