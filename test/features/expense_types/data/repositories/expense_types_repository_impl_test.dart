import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/expense_types/data/datasources/expense_types_remote_data_source.dart';
import 'package:horus_system/features/expense_types/data/models/expense_type_model.dart';
import 'package:horus_system/features/expense_types/data/repositories/expense_types_repository_impl.dart';
import 'package:horus_system/features/expense_types/domain/entities/expense_type_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseTypesRepositoryImpl', () {
    test('forwards company scope for settings and active lookups', () async {
      final dataSource = _FakeExpenseTypesRemoteDataSource();
      final repository = _repository(dataSource);

      await repository.getExpenseTypes(companyId: _companyId);
      expect(dataSource.lastListCompanyId, _companyId);

      await repository.getActiveExpenseTypes(companyId: _companyId);
      expect(dataSource.lastActiveCompanyId, _companyId);
    });

    test('creates then audits only after successful mutation', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(operations: operations);
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.addExpenseType(
        data: const ExpenseTypeWriteData(companyId: _companyId, name: 'Fuel'),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(operations, ['add', 'audit']);
      expect(auditRepository.lastData?.entityType, AuditEntityType.expenseType);
      expect(auditRepository.lastData?.description, 'expense_type_created');
      expect(auditRepository.lastData?.companyId, _companyId);
    });

    test('update snapshots old values before mutation and audit', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(operations: operations);
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.updateExpenseType(
        expenseTypeId: _typeId,
        data: const ExpenseTypeWriteData(
          companyId: _companyId,
          name: 'Road fees',
        ),
        actorRole: 'admin',
      );

      expect(result, isA<Success>());
      expect(operations, ['get_by_id', 'update', 'audit']);
      expect(auditRepository.lastData?.oldValues?['name'], 'Fuel');
      expect(auditRepository.lastData?.newValues?['name'], 'Road fees');
    });

    test('does not audit when mutation fails', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        operations: operations,
        addError: StateError('internal'),
      );
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.addExpenseType(
        data: const ExpenseTypeWriteData(companyId: _companyId, name: 'Fuel'),
        actorRole: 'owner',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(operations, ['add']);
      expect(auditRepository.lastData, isNull);
    });
  });
}

const _companyId = 'company-1';
const _typeId = 'type-1';

ExpenseTypesRepositoryImpl _repository(
  _FakeExpenseTypesRemoteDataSource dataSource, [
  _FakeAuditRepository? auditRepository,
]) {
  return ExpenseTypesRepositoryImpl(
    remoteDataSource: dataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditRepository(),
    ),
  );
}

ExpenseTypeModel _model({String name = 'Fuel', bool isActive = true}) {
  return ExpenseTypeModel(
    id: _typeId,
    companyId: _companyId,
    name: name,
    isActive: isActive,
  );
}

class _FakeExpenseTypesRemoteDataSource implements ExpenseTypesRemoteDataSource {
  final List<String>? operations;
  final Object? addError;
  String? lastListCompanyId;
  String? lastActiveCompanyId;

  _FakeExpenseTypesRemoteDataSource({this.operations, this.addError});

  @override
  Future<List<ExpenseTypeModel>> getExpenseTypes({required String companyId}) async {
    lastListCompanyId = companyId;
    return [_model()];
  }

  @override
  Future<List<ExpenseTypeModel>> getActiveExpenseTypes({required String companyId}) async {
    lastActiveCompanyId = companyId;
    return [_model()];
  }

  @override
  Future<ExpenseTypeModel> getExpenseTypeById({
    required String companyId,
    required String expenseTypeId,
  }) async {
    operations?.add('get_by_id');
    return _model();
  }

  @override
  Future<ExpenseTypeModel> addExpenseType({required ExpenseTypeWriteData data}) async {
    operations?.add('add');
    if (addError != null) throw addError!;
    return _model(name: data.name);
  }

  @override
  Future<ExpenseTypeModel> updateExpenseType({
    required String expenseTypeId,
    required ExpenseTypeWriteData data,
  }) async {
    operations?.add('update');
    return _model(name: data.name);
  }

  @override
  Future<ExpenseTypeModel> deactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
  }) async {
    operations?.add('deactivate');
    return _model(isActive: false);
  }

  @override
  Future<ExpenseTypeModel> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
  }) async {
    operations?.add('reactivate');
    return _model(isActive: true);
  }
}

class _FakeAuditRepository implements AuditLogRepository {
  final List<String>? operations;
  AuditLogWriteData? lastData;

  _FakeAuditRepository({this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    lastData = data;
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
