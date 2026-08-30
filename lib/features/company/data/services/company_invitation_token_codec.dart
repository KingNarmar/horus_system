import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class CompanyInvitationTokenMaterial {
  final String rawToken;
  final String postgresByteaHash;

  const CompanyInvitationTokenMaterial({
    required this.rawToken,
    required this.postgresByteaHash,
  });
}

class CompanyInvitationTokenCodec {
  final Random _random;

  CompanyInvitationTokenCodec({Random? random}) : _random = random ?? Random.secure();

  CompanyInvitationTokenMaterial generate() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final rawToken = base64UrlEncode(bytes).replaceAll('=', '');
    return CompanyInvitationTokenMaterial(
      rawToken: rawToken,
      postgresByteaHash: hashForPostgres(rawToken),
    );
  }

  String hashForPostgres(String rawToken) {
    final digest = sha256.convert(utf8.encode(rawToken));
    return '\\x${digest.toString()}';
  }
}
