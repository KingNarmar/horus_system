// Issue #317 R5.1 — pure verification contracts for Development token renewal.
// This is a test tool, never imported by lib/. Never print token values.

import 'dart:convert';

import 'issue_317_r44_dev_test_client.dart';

final class R51RenewedCredentials {
  final String userId;
  final String accessToken;
  final String refreshToken;

  const R51RenewedCredentials({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });
}

/// Validate both the Supabase Auth response and the signed JWT's identity.
/// No external token, user record, or backend error is ever interpolated into
/// thrown exceptions. Authorization is checked separately against RLS.
R51RenewedCredentials r51ReadCredentials(Object? body, {DateTime? now}) {
  if (body is! Map || body['user'] is! Map) {
    throw const FormatException('Authentication response structure invalid.');
  }

  final userId = (body['user'] as Map)['id'];
  final accessToken = body['access_token'];
  final refreshToken = body['refresh_token'];

  if (userId is! String ||
      !isR44Uuid(userId) ||
      accessToken is! String ||
      refreshToken is! String ||
      refreshToken.isEmpty) {
    throw const FormatException('Authenticated credentials invalid.');
  }

  final parts = accessToken.split('.');
  if (parts.length != 3 || parts.any((part) => part.isEmpty)) {
    throw const FormatException('Authenticated JWT structure invalid.');
  }

  Object? payload;
  try {
    payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
  } on FormatException {
    throw const FormatException('Authenticated JWT claims invalid.');
  }

  if (payload is! Map ||
      payload['sub'] != userId ||
      payload['role'] != 'authenticated') {
    throw const FormatException('Authenticated JWT identity invalid.');
  }

  final expiresAt = payload['exp'];
  final currentSeconds = (now ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
  if (expiresAt is! num || expiresAt <= currentSeconds) {
    throw const FormatException('Authenticated JWT is expired.');
  }

  return R51RenewedCredentials(
    userId: userId,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}

/// Require a distinct refresh token and the same user following renewal.
void r51VerifyRotation(
  R51RenewedCredentials before,
  R51RenewedCredentials after,
) {
  if (before.userId != after.userId ||
      before.refreshToken == after.refreshToken) {
    throw const FormatException('Session identity or rotation invalid.');
  }
}

/// A one-row active company-role snapshot must be returned by server-side RLS.
bool r51HasExpectedMembership(
  List<Map<String, dynamic>> rows, {
  required String companyId,
  required String role,
}) =>
    rows.length == 1 &&
    rows.single['company_id'] == companyId &&
    rows.single['is_active'] == true &&
    rows.single['role'] == role;
