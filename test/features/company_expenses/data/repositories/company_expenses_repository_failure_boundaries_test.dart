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

    test('sanitizes unexpected add mutation failures', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
        addError: Exception('mutation internal detail'),
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_expense']);
    });

    test('sanitizes Postgrest add mutation failures', () async {
      final operations = <String>[];
      const backendError = PostgrestException(
        message: 'permission denied',
        code: '42501',
        details: 'sensitive mutation detail',
        hint: 'sensitive mutation hint',
      );
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
        addError: backendError,
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_expense']);
    });

    test('sanitizes update mutation failures without an audit lookup', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
        updateError: Exception('update internal detail'),
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.updateCompanyExpense(
        id: testExpenseId,
        data: companyExpenseWriteData(amount: 175),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['update_expense']);
      expect(remoteDataSource.lastLookupCompanyId, isNull);
      expect(remoteDataSource.lastLookupExpenseId, isNull);
    });

    test('sanitizes void mutation failures without an audit lookup', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
        voidError: Exception('void internal detail'),
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.voidCompanyExpense(
        data: companyExpenseVoidData,
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['void_expense']);
      expect(remoteDataSource.lastLookupCompanyId, isNull);
      expect(remoteDataSource.lastLookupExpenseId, isNull);
    });
  });
}
