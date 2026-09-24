import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

import 'company_expenses_repository_test_support.dart';

void main() {
  group('CompanyExpensesRepositoryImpl failure boundaries', () {
    test(
      'sanitizes Postgrest read failure and preserves company forwarding',
      () async {
        const backendError = PostgrestException(
          message: 'sensitive read message',
          code: '42501',
          details: 'sensitive read detail',
          hint: 'sensitive read hint',
        );
        final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
          listError: backendError,
        );
        final repository = createCompanyExpensesRepository(remoteDataSource);

        final result = await repository.getCompanyExpenses(
          companyId: testCompanyId,
          includeVoided: true,
        );

        expect(result, isA<FailureResult>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, testCompanyId);
        expect(remoteDataSource.lastIncludeVoided, isTrue);
      },
    );

    test('sanitizes model mapping failures inside repository guard', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        listModels: [ThrowingCompanyExpenseModel()],
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.getCompanyExpenses(
        companyId: testCompanyId,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes unexpected add failure', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        addError: Exception('mutation internal detail'),
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes Postgrest add failure', () async {
      const backendError = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'sensitive mutation detail',
        hint: 'sensitive mutation hint',
      );
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        addError: backendError,
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes update mutation failure', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        updateError: Exception('update internal detail'),
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.updateCompanyExpense(
        id: testExpenseId,
        data: companyExpenseWriteData(amount: 175),
        actorRole: 'accountant',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes void mutation failure', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        voidError: Exception('void internal detail'),
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.voidCompanyExpense(
        data: companyExpenseVoidData,
        actorRole: 'accountant',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });
  });
}
