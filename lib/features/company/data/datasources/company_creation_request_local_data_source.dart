import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores only an idempotency UUID and payload fingerprint, never form fields.
abstract interface class CompanyCreationRequestLocalDataSource {
  Future<String?> read(String userId);

  Future<void> write(String userId, String encodedRequest);

  Future<void> delete(String userId);
}

/// Scoped to the authenticated actor so device account switching cannot
/// replay another user's pending company creation.
final class SecureCompanyCreationRequestLocalDataSource
    implements CompanyCreationRequestLocalDataSource {
  static const _keyPrefix = 'company_creation_pending_v1_';

  final FlutterSecureStorage _storage;

  const SecureCompanyCreationRequestLocalDataSource(this._storage);

  @override
  Future<String?> read(String userId) =>
      _storage.read(key: '$_keyPrefix$userId');

  @override
  Future<void> write(String userId, String encodedRequest) =>
      _storage.write(key: '$_keyPrefix$userId', value: encodedRequest);

  @override
  Future<void> delete(String userId) =>
      _storage.delete(key: '$_keyPrefix$userId');
}
