import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/account_deletion_db_fields.dart';
import '../models/account_deletion_status_model.dart';

abstract interface class AccountDeletionRemoteDataSource {
  Future<AccountDeletionStatusModel?> getStatus();
  Future<AccountDeletionStatusModel> requestDeletion();
  Future<AccountDeletionStatusModel?> cancelDeletion();
}

final class SupabaseAccountDeletionRemoteDataSource
    implements AccountDeletionRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseAccountDeletionRemoteDataSource(this._client);

  @override
  Future<AccountDeletionStatusModel?> getStatus() async {
    return _readOptional(await _client.rpc(AccountDeletionDbFields.getStatusRpc));
  }

  @override
  Future<AccountDeletionStatusModel> requestDeletion() async {
    final model = _readOptional(
      await _client.rpc(AccountDeletionDbFields.requestRpc),
    );
    if (model == null) {
      throw const PostgrestException(
        message: 'account_deletion_request_missing',
      );
    }
    return model;
  }

  @override
  Future<AccountDeletionStatusModel?> cancelDeletion() async {
    return _readOptional(await _client.rpc(AccountDeletionDbFields.cancelRpc));
  }

  AccountDeletionStatusModel? _readOptional(Object? response) {
    if (response is! List || response.isEmpty) return null;
    final row = response.first;
    if (row is! Map) return null;
    return AccountDeletionStatusModel.fromJson(
      Map<String, dynamic>.from(row),
    );
  }
}
