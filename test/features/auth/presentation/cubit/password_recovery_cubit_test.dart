import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/repositories/password_recovery_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:horus_system/features/auth/presentation/cubit/password_recovery_cubit.dart';
import 'package:horus_system/features/auth/presentation/cubit/password_recovery_state.dart';
import 'package:test/test.dart';

void main() {
  group('PasswordRecoveryCubit', () {
    test('starts initial and emits submitting then submitted', () async {
      final repository = _FakePasswordRecoveryRepository();
      final cubit = PasswordRecoveryCubit(
        requestPasswordRecovery: RequestPasswordRecoveryUseCase(repository),
      );
      addTearDown(cubit.close);

      expect(cubit.state, isA<PasswordRecoveryInitial>());
      final states = cubit.stream.take(2).toList();
      await cubit.requestRecovery(email: 'user@example.com');

      expect(
        (await states).map((state) => state.runtimeType),
        [PasswordRecoverySubmitting, PasswordRecoverySubmitted],
      );
      expect(repository.calls, 1);
    });

    test('emits typed failure after submitting', () async {
      const failure = AuthFailure(code: FailureCodes.authRateLimited);
      final repository = _FakePasswordRecoveryRepository(
        result: const FailureResult<void>(failure),
      );
      final cubit = PasswordRecoveryCubit(
        requestPasswordRecovery: RequestPasswordRecoveryUseCase(repository),
      );
      addTearDown(cubit.close);

      final states = cubit.stream.take(2).toList();
      await cubit.requestRecovery(email: 'user@example.com');
      final emitted = await states;

      expect(emitted[0], isA<PasswordRecoverySubmitting>());
      expect((emitted[1] as PasswordRecoveryFailure).failure, same(failure));
    });
  });
}

final class _FakePasswordRecoveryRepository
    implements PasswordRecoveryRepository {
  _FakePasswordRecoveryRepository({this.result = const Success<void>(null)});

  final Result<void> result;
  int calls = 0;

  @override
  Future<Result<void>> requestPasswordRecovery({required String email}) async {
    calls++;
    return result;
  }
}
