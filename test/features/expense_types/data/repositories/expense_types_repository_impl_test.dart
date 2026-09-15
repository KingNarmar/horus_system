import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/expense_types/data/datasources/expense_types_remote_data_source.dart';
import 'package:horus_system/features/expense_types/data/models/expense_type_model.dart';
import 'package:horus_system/features/expense_types/data/repositories/expense_types_repository_impl.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseTypesRepositoryImpl', () {
    test('forwards company scope for every catalog read', () async {
      final dataSource = _FakeExpenseTypesRemoteDataSource();
      final repository = ExpenseTypesRepositoryImpl(
        remoteDataSource: dataSource,
      );

      await repository.getExpenseTypes(companyId: _companyId);
      await repository.getActiveExpenseTypes(companyId: _companyId);
      await repository.getLedgerEligibleExpenseTypes(companyId: _companyId);

      expect(dataSource.lastCatalogCompanyId, _companyId);
      expect(dataSource.lastActiveCompanyId, _companyId);
      expect(dataSource.lastLedgerEligibleCompanyId, _companyId);
    });

    test('maps canonical taxonomy fields to the domain entity', () async {
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        models: const [
          ExpenseTypeModel(
            id: _typeId,
            companyId: _companyId,
            name: 'Fuel',
            code: 'fuel',
            isActive: true,
            isLedgerEligible: true,
          ),
        ],
      );
      final repository = ExpenseTypesRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final result = await repository.getExpenseTypes(companyId: _companyId);
      final expenseType = result.dataOrNull?.single;

      expect(result, isA<Success>());
      expect(expenseType?.code, 'fuel');
      expect(expenseType?.isLedgerEligible, isTrue);
    });

    test('maps unexpected read errors to a typed failure', () async {
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        error: StateError('internal detail'),
      );
      final repository = ExpenseTypesRepositoryImpl(
        remoteDataSource: dataSource,
      );

      final result = await repository.getExpenseTypes(companyId: _companyId);

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
    });
  });
}

const _companyId = 'company-1';
const _typeId = 'type-1';

class _FakeExpenseTypesRemoteDataSource
    implements ExpenseTypesRemoteDataSource {
  final List<ExpenseTypeModel> models;
  final Object? error;
  String? lastCatalogCompanyId;
  String? lastActiveCompanyId;
  String? lastLedgerEligibleCompanyId;

  _FakeExpenseTypesRemoteDataSource({this.models = const [], this.error});

  @override
  Future<List<ExpenseTypeModel>> getExpenseTypes({
    required String companyId,
  }) async {
    lastCatalogCompanyId = companyId;
    _throwIfNeeded();
    return models;
  }

  @override
  Future<List<ExpenseTypeModel>> getActiveExpenseTypes({
    required String companyId,
  }) async {
    lastActiveCompanyId = companyId;
    _throwIfNeeded();
    return models;
  }

  @override
  Future<List<ExpenseTypeModel>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) async {
    lastLedgerEligibleCompanyId = companyId;
    _throwIfNeeded();
    return models;
  }

  void _throwIfNeeded() {
    final currentError = error;
    if (currentError != null) throw currentError;
  }
}
