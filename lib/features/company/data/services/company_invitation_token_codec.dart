import 'dart:convert';

import 'package:crypto/crypto.dart';

class CompanyInvitationTokenCodec {
  const CompanyInvitationTokenCodec();

  String hashForPostgres(String rawToken) {
    final digest = sha256.convert(utf8.encode(rawToken));
    return '\\x${digest.toString()}';
  }
}
