import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SelectedCompanyPreferenceLocalDataSource {
  Future<String?> read(String userId);

  Future<void> write(String userId, String companyId);
}

/// Only the company ID is stored, under the current user ID on this device.
/// No membership, role, session token, or tenant business data is persisted.
final class SecureSelectedCompanyPreferenceLocalDataSource
    implements SelectedCompanyPreferenceLocalDataSource {
  static const _keyPrefix = 'selected_company_v1_';

  final FlutterSecureStorage _storage;

  const SecureSelectedCompanyPreferenceLocalDataSource(this._storage);

  @override
  Future<String?> read(String userId) =>
      _storage.read(key: '$_keyPrefix$userId');

  @override
  Future<void> write(String userId, String companyId) =>
      _storage.write(key: '$_keyPrefix$userId', value: companyId);
}
