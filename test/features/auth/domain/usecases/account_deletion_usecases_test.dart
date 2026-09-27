import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/usecases/usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/account_deletion_status.dart';
import 'package:horus_system/features/auth/domain/repositories/account_deletion_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/cancel_account_deletion_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/get_account_deletion_status_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/request_account_deletion_usecase.dart';

void main() {
  const none = AccountDeletionStatus(state: AccountDeletionRequestState.none);
  final pending = AccountDeletionStatus(
    state: AccountDeletionRequestState.pending,
    requestedAt: DateTime.utc(2026, 9, 27),
    scheduledFor: DateTime.utc(2026, 10, 4),
  );

  test('get status delegates to repository', () async {
    final repository = _FakeRepository(getResult: const Success(none));
    final result = await GetAccountDeletionStatusUseCase(repository)(
      const NoParams(),
    );
    expect(result.dataOrNull, same(none));
    expect(repository.getCalls, 1);
  });

  test('request deletion delegates to repository', () async {
    final repository = _FakeRepository(requestResult: Success(pending));
    final result = await RequestAccountDeletionUseCase(repository)(
      const NoParams(),
    );
    expect(result.dataOrNull, same(pending));
    expect(repository.requestCalls, 1);
  });

  test('cancel deletion delegates to repository', () async {
    final repository = _FakeRepository(cancelResult: const Success(none));
    final result = await CancelAccountDeletionUseCase(repository)(
      const NoParams(),
    );
    expect(result.dataOrNull, same(none));
    expect(repository.cancelCalls, 1);
  });
}

final class _FakeRepository implements AccountDeletionRepository {
  final Result<AccountDeletionStatus>? getResult;
  final Result<AccountDeletionStatus>? requestResult;
  final Result<AccountDeletionStatus>? cancelResult;

  int getCalls = 0;
  int requestCalls = 0;
  int cancelCalls = 0;

  _FakeRepository({this.getResult, this.requestResult, this.cancelResult});

  @override
  Future<Result<AccountDeletionStatus>> getStatus() async {
    getCalls += 1;
    return getResult!;
  }

  @override
  Future<Result<AccountDeletionStatus>> requestDeletion() async {
    requestCalls += 1;
    return requestResult!;
  }

  @override
  Future<Result<AccountDeletionStatus>> cancelDeletion() async {
    cancelCalls += 1;
    return cancelResult!;
  }
}
