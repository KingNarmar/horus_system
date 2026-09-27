import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/data/datasources/account_deletion_remote_data_source.dart';
import 'package:horus_system/features/auth/data/models/account_deletion_status_model.dart';
import 'package:horus_system/features/auth/data/repositories/account_deletion_repository_impl.dart';
import 'package:horus_system/features/auth/domain/entities/account_deletion_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('AccountDeletionRepositoryImpl', () {
    test('maps absent status to non-pending domain status', () async {
      final repository = AccountDeletionRepositoryImpl(_FakeDataSource());

      final result = await repository.getStatus();

      expect(result, isA<Success<AccountDeletionStatus>>());
      expect(
        (result as Success<AccountDeletionStatus>).value.isPending,
        isFalse,
      );
    });

    test('maps pending model to pending domain status', () async {
      final repository = AccountDeletionRepositoryImpl(
        _FakeDataSource(status: _pendingModel),
      );

      final result = await repository.getStatus();

      expect(
        (result as Success<AccountDeletionStatus>).value.isPending,
        isTrue,
      );
    });

    test('maps sole-owner database rejection to typed failure code', () async {
      final repository = AccountDeletionRepositoryImpl(
        _FakeDataSource(
          requestError: const PostgrestException(
            message: 'account_deletion_sole_owner',
            code: 'P1961',
          ),
        ),
      );

      final result = await repository.requestDeletion();

      expect(result, isA<FailureResult<AccountDeletionStatus>>());
      expect(
        (result as FailureResult<AccountDeletionStatus>).failure.code,
        FailureCodes.accountDeletionSoleOwner,
      );
    });
  });
}

final _pendingModel = AccountDeletionStatusModel(
  status: 'pending',
  requestedAt: DateTime.utc(2026, 9, 27),
  scheduledFor: DateTime.utc(2026, 10, 4),
);

final class _FakeDataSource implements AccountDeletionRemoteDataSource {
  _FakeDataSource({
    this.status,
    this.requestError,
  });

  final AccountDeletionStatusModel? status;
  final Object? requestError;

  @override
  Future<AccountDeletionStatusModel?> getStatus() async => status;

  @override
  Future<AccountDeletionStatusModel> requestDeletion() async {
    final error = requestError;
    if (error != null) throw error;
    return status ?? _pendingModel;
  }

  @override
  Future<AccountDeletionStatusModel?> cancelDeletion() async => null;
}
