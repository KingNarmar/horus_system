import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/usecases/usecase.dart';
import 'package:horus_system/core/utils/result.dart';

class FakeSuccessUseCase implements UseCase<String, NoParams> {
  @override
  Future<Result<String>> call(NoParams params) async {
    return const Success<String>('success');
  }
}

class FakeFailureUseCase implements UseCase<String, NoParams> {
  @override
  Future<Result<String>> call(NoParams params) async {
    return const FailureResult<String>(
      ValidationFailure(message: 'Invalid input'),
    );
  }
}

void main() {
  group('UseCase', () {
    test('returns Success result correctly', () async {
      final useCase = FakeSuccessUseCase();

      final result = await useCase(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.dataOrNull, 'success');
      expect(result.failureOrNull, isNull);
    });

    test('returns FailureResult correctly', () async {
      final useCase = FakeFailureUseCase();

      final result = await useCase(const NoParams());

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.dataOrNull, isNull);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, 'Invalid input');
    });

    test('when handles both success and failure branches', () async {
      final successResult = await FakeSuccessUseCase()(const NoParams());
      final failureResult = await FakeFailureUseCase()(const NoParams());

      final successMessage = successResult.when(
        success: (data) => data,
        failure: (failure) => failure.message,
      );

      final failureMessage = failureResult.when(
        success: (data) => data,
        failure: (failure) => failure.message,
      );

      expect(successMessage, 'success');
      expect(failureMessage, 'Invalid input');
    });
  });
}
