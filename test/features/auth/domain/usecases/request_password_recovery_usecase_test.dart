import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/auth/domain/repositories/password_recovery_repository.dart';
import 'package:horus_system/features/auth/domain/usecases/request_password_recovery_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('RequestPasswordRecoveryUseCase', () {
    test('rejects empty email without calling repository', () async {
      final repository = _FakePasswordRecoveryRepository();
      final useCase = RequestPasswordRecoveryUseCase(repository);

      final result = await useCase(
        const RequestPasswordRecoveryParams(email: '   '),
      );

      expect(result.failureOrNull?.code, FailureCodes.authEmailRequired);
      expect(repository.calls, 0);
    });

    test('rejects malformed email without calling repository', () async {
      final repository = _FakePasswordRecoveryRepository();
      final useCase = RequestPasswordRecoveryUseCase(repository);

      final result = await useCase(
        const RequestPasswordRecoveryParams(email: 'invalid-email'),
      );

      expect(result.failureOrNull?.code, FailureCodes.authInvalidEmail);
      expect(repository.calls, 0);
    });

    test('trims email and preserves repository result', () async {
      const expected = Success<void>(null);
      final repository = _FakePasswordRecoveryRepository(result: expected);
      final useCase = RequestPasswordRecoveryUseCase(repository);

      final result = await useCase(
        const RequestPasswordRecoveryParams(
          email: '  user@example.com  ',
        ),
      );

      expect(result, same(expected));
      expect(repository.calls, 1);
      expect(repository.lastEmail, 'user@example.com');
    });

    test('preserves typed repository failure', () async {
      const failure = AuthFailure(code: FailureCodes.authRateLimited);
      const expected = FailureResult<void>(failure);
      final repository = _FakePasswordRecoveryRepository(result: expected);
      final useCase = RequestPasswordRecoveryUseCase(repository);

      final result = await useCase(
        const RequestPasswordRecoveryParams(email: 'user@example.com'),
      );

      expect(result, same(expected));
    });
  });
}

final class _FakePasswordRecoveryRepository
    implements PasswordRecoveryRepository {
  _FakePasswordRecoveryRepository({this.result = const Success<void>(null)});

  final Result<void> result;
  int calls = 0;
  String? lastEmail;

  @override
  Future<Result<void>> requestPasswordRecovery({required String email}) async {
    calls++;
    lastEmail = email;
    return result;
  }
}
