import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Keeps a secure request identity stable across retries of the same payload.
///
/// The caller must retain this instance for the onboarding session. A successful
/// response releases the request, while an uncertain network failure does not.
/// Server-side actor scoping, payload verification and concurrency limits remain
/// authoritative.
final class CompanyCreationRequestIdentity {
  String? _fingerprint;
  String? _requestId;

  String getOrCreate(Map<String, Object?> parameters) {
    final fingerprint = sha256.convert(utf8.encode(jsonEncode(parameters))).toString();
    if (fingerprint != _fingerprint || _requestId == null) {
      _fingerprint = fingerprint;
      _requestId = _generateSecureUuid();
    }
    return _requestId!;
  }

  void complete(String requestId) {
    if (requestId != _requestId) return;
    _fingerprint = null;
    _requestId = null;
  }

  String _generateSecureUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
