import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

import 'company_expenses_repository_test_support.dart';

void main() {
  group('CompanyExpensesRepositoryImpl', () {
    test('adds expense through the business data source', () async {
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

    test('updates without a client-side audit snapshot lookup', () async {
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
      expect(remoteDataSource.lastLookupCompanyId, isNull);
      expect(remoteDataSource.lastLookupExpenseId, isNull);
    });

    test('voids without a client-side audit snapshot lookup', () async {
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
      expect(remoteDataSource.lastLookupCompanyId, isNull);
      expect(remoteDataSource.lastLookupExpenseId, isNull);
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
