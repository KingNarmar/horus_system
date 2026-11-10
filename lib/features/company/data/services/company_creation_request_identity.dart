import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../datasources/company_creation_request_local_data_source.dart';

/// Raised when local retry state cannot be safely read or persisted.
final class CompanyCreationRequestIdentityException implements Exception {
  const CompanyCreationRequestIdentityException();
}

/// Keeps the original request UUID across app restarts and uncertain replies.
///
/// Identity is scoped to the authenticated actor, with no company form values
/// stored locally. A changed payload cannot silently replace an unresolved
/// request: the protected RPC makes the final idempotency decision.
final class CompanyCreationRequestIdentity {
  static const _requestIdKey = 'request_id';
  static const _fingerprintKey = 'fingerprint';

  final CompanyCreationRequestLocalDataSource _localDataSource;

  const CompanyCreationRequestIdentity(this._localDataSource);

  Future<String> getOrCreate({
    required String userId,
    required Map<String, Object?> parameters,
  }) async {
    try {
      final stored = await _localDataSource.read(userId);
      if (stored != null) {
        final parsed = jsonDecode(stored);
        if (parsed is! Map<String, dynamic>) {
          throw const FormatException('Invalid pending creation request');
        }
        final id = parsed[_requestIdKey];
        final fingerprint = parsed[_fingerprintKey];
        if (id is! String ||
            !_uuidVersionFour.hasMatch(id) ||
            fingerprint is! String ||
            !_sha256Hash.hasMatch(fingerprint)) {
          throw const FormatException('Invalid pending request metadata');
        }

        // The original UUID is retained until the server has returned a
        // definitive success/failure. Different input cannot mask a replay.
        return id;
      }

      final id = _generateSecureUuid();
      final fingerprint = sha256
          .convert(utf8.encode(jsonEncode(parameters)))
          .toString();
      await _localDataSource.write(
        userId,
        jsonEncode({_requestIdKey: id, _fingerprintKey: fingerprint}),
      );
      return id;
    } catch (_) {
      throw const CompanyCreationRequestIdentityException();
    }
  }

  Future<void> complete({
    required String userId,
    required String requestId,
  }) async {
    try {
      final stored = await _localDataSource.read(userId);
      if (stored == null) return;
      final decoded = jsonDecode(stored);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid pending creation request');
      }
      if (decoded[_requestIdKey] == requestId) {
        await _localDataSource.delete(userId);
      }
    } catch (_) {
      throw const CompanyCreationRequestIdentityException();
    }
  }

  static final _uuidVersionFour = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );
  static final _sha256Hash = RegExp(r'^[0-9a-f]{64}$');

  String _generateSecureUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
