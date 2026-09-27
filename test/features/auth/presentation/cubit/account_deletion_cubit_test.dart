import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/entities/account_deletion_status.dart';
import 'package:horus_system/features/auth/domain/repositories/account_deletion_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/cancel_account_deletion_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/get_account_deletion_status_usecase.dart';
import 'package:horus_system/features/auth/domain/usecases/request_account_deletion_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/account_deletion_cubit.dart';
import 'package:horus_system/features/auth/presentation/cubit/account_deletion_state.dart';
import 'package:test/test.dart';

void main() {
  group('AccountDeletionCubit', () {
    test('load emits loading then current status', () async {
      final repository = _FakeRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = cubit.stream.take(2).toList();
      await cubit.load();

      expect((await states).map((state) => state.runtimeType), [
        AccountDeletionLoading,
        AccountDeletionReady,
      ]);
      expect(repository.getCalls, 1);
    });

    test('request emits pending status', () async {
      final repository = _FakeRepository(
        requestResult: const Success<AccountDeletionStatus>(_pending),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = cubit.stream.take(2).toList();
      await cubit.requestDeletion();

      final emitted = await states;
      expect(emitted.first, isA<AccountDeletionLoading>());
      expect(
        (emitted.last as AccountDeletionReady).status.isPending,
        isTrue,
      );
      expect(repository.requestCalls, 1);
    });

    test('request exposes typed domain failure', () async {
      const failure = ConflictFailure(code: 'account_deletion_sole_owner');
      final repository = _FakeRepository(
        requestResult:
            const FailureResult<AccountDeletionStatus>(failure),
      );
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = cubit.stream.take(2).toList();
      await cubit.requestDeletion();

      final emitted = await states;
      expect((emitted.last as AccountDeletionFailure).failure, same(failure));
    });

    test('cancel returns account to non-pending state', () async {
      final repository = _FakeRepository();
      final cubit = _createCubit(repository);
      addTearDown(cubit.close);

      final states = cubit.stream.take(2).toList();
      await cubit.cancelDeletion();

      final emitted = await states;
      expect(
        (emitted.last as AccountDeletionReady).status.isPending,
        isFalse,
      );
      expect(repository.cancelCalls, 1);
    });
  });
}

const _none = AccountDeletionStatus(
  state: AccountDeletionRequestState.none,
);

const _pending = AccountDeletionStatus(
  state: AccountDeletionRequestState.pending,
);

AccountDeletionCubit _createCubit(_FakeRepository repository) {
  return AccountDeletionCubit(
    getStatus: GetAccountDeletionStatusUseCase(repository),
    requestDeletion: RequestAccountDeletionUseCase(repository),
    cancelDeletion: CancelAccountDeletionUseCase(repository),
  );
}

final class _FakeRepository implements AccountDeletionRepository {
  _FakeRepository({
    Result<AccountDeletionStatus>? getResult,
    Result<AccountDeletionStatus>? requestResult,
    Result<AccountDeletionStatus>? cancelResult,
  }) : getResult = getResult ?? const Success<AccountDeletionStatus>(_none),
       requestResult =
           requestResult ?? const Success<AccountDeletionStatus>(_pending),
       cancelResult =
           cancelResult ?? const Success<AccountDeletionStatus>(_none);

  final Result<AccountDeletionStatus> getResult;
  final Result<AccountDeletionStatus> requestResult;
  final Result<AccountDeletionStatus> cancelResult;

  int getCalls = 0;
  int requestCalls = 0;
  int cancelCalls = 0;

  @override
  Future<Result<AccountDeletionStatus>> getStatus() async {
    getCalls++;
    return getResult;
  }

  @override
  Future<Result<AccountDeletionStatus>> requestDeletion() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<Result<AccountDeletionStatus>> cancelDeletion() async {
    cancelCalls++;
    return cancelResult;
  }
}
