import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class PendingCompanyInvitationLocalDataSource {
  Future<void> saveToken(String token);

  Future<String?> readToken();

  Future<void> clearToken();
}

class SecurePendingCompanyInvitationLocalDataSource
    implements PendingCompanyInvitationLocalDataSource {
  static const _tokenKey = 'company_invitation_pending_token';

  final FlutterSecureStorage _storage;

  const SecurePendingCompanyInvitationLocalDataSource(this._storage);

  @override
  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  @override
  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}
