import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

import 'company_expenses_repository_test_support.dart';

void main() {
  group('CompanyExpensesRepositoryImpl', () {
    test('adds expense and writes audit after successful mutation', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeCompanyExpenseAuditLogRepository(
        operations: operations,
      );
      final repository = createCompanyExpensesRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, testExpenseId);
      expect(operations, ['add_expense', 'audit']);
      expect(
        auditRepository.logs.single.description,
        'company_expense_created',
      );
    });

    test('propagates audit failure after successful mutation', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource();
      final auditRepository = FakeCompanyExpenseAuditLogRepository(
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = createCompanyExpensesRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(remoteDataSource.addCalls, 1);
    });

    test('updates after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeCompanyExpenseAuditLogRepository(
        operations: operations,
      );
      final repository = createCompanyExpensesRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.updateCompanyExpense(
        id: testExpenseId,
        data: companyExpenseWriteData(amount: 175),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.amount, 175);
      expect(operations, ['get_expense', 'update_expense', 'audit']);
      expect(remoteDataSource.lastLookupCompanyId, testCompanyId);
      expect(remoteDataSource.lastLookupExpenseId, testExpenseId);
      expect(
        auditRepository.logs.single.description,
        'company_expense_updated',
      );
      expect(auditRepository.logs.single.oldValues?['amount'], 125.5);
      expect(auditRepository.logs.single.newValues?['amount'], 175);
    });

    test('voids after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = FakeCompanyExpenseAuditLogRepository(
        operations: operations,
      );
      final repository = createCompanyExpensesRepository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.voidCompanyExpense(
        data: companyExpenseVoidData,
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.isVoided, isTrue);
      expect(operations, ['get_expense', 'void_expense', 'audit']);
      expect(remoteDataSource.lastLookupCompanyId, testCompanyId);
      expect(remoteDataSource.lastLookupExpenseId, testExpenseId);
      expect(auditRepository.logs.single.description, 'company_expense_voided');
      expect(auditRepository.logs.single.oldValues?['is_voided'], isFalse);
      expect(auditRepository.logs.single.newValues?['is_voided'], isTrue);
    });

    test('forwards company scope when loading expenses', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource();
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.getCompanyExpenses(
        companyId: testCompanyId,
        includeVoided: true,
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastListCompanyId, testCompanyId);
      expect(remoteDataSource.lastIncludeVoided, isTrue);
    });

    test('forwards company scope and flag when loading categories', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource();
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.getCategories(
        companyId: testCompanyId,
        includeInactive: true,
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastCategoriesCompanyId, testCompanyId);
      expect(remoteDataSource.lastIncludeInactive, isTrue);
    });

    test('forwards company scope when loading form lookups', () async {
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource();
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.getFormLookups(companyId: testCompanyId);

      expect(result, isA<Success>());
      expect(remoteDataSource.lastFormLookupsCompanyId, testCompanyId);
    });
  });
}
