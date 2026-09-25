import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

import 'company_expenses_repository_test_support.dart';

void main() {
  group('CompanyExpensesRepositoryImpl', () {
    test('adds expense through the company-scoped data source', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.addCompanyExpense(
        data: companyExpenseWriteData(),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, testExpenseId);
      expect(operations, ['add_expense']);
    });

    test('updates expense without a redundant audit snapshot lookup', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.updateCompanyExpense(
        id: testExpenseId,
        data: companyExpenseWriteData(amount: 175),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.amount, 175);
      expect(operations, ['update_expense']);
    });

    test('voids expense without a redundant audit snapshot lookup', () async {
      final operations = <String>[];
      final remoteDataSource = FakeCompanyExpensesRemoteDataSource(
        operations: operations,
      );
      final repository = createCompanyExpensesRepository(remoteDataSource);

      final result = await repository.voidCompanyExpense(
        data: companyExpenseVoidData,
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.isVoided, isTrue);
      expect(operations, ['void_expense']);
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
