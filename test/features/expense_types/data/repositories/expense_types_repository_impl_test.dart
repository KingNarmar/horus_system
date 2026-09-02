import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
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
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        operations: operations,
      );
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

    test('propagates audit failure after successful create mutation', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditRepository(
        operations: operations,
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.addExpenseType(
        data: const ExpenseTypeWriteData(companyId: _companyId, name: 'Fuel'),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(operations, ['add', 'audit']);
    });

    test('update snapshots old values before mutation and audit', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        operations: operations,
      );
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

    test('snapshot failure stops update before mutation and audit', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        operations: operations,
        getByIdError: StateError('snapshot detail'),
      );
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

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(operations, ['get_by_id']);
      expect(auditRepository.lastData, isNull);
    });

    test(
      'deactivate snapshots state, mutates, then audits lifecycle',
      () async {
        final operations = <String>[];
        final dataSource = _FakeExpenseTypesRemoteDataSource(
          operations: operations,
        );
        final auditRepository = _FakeAuditRepository(operations: operations);
        final repository = _repository(dataSource, auditRepository);

        final result = await repository.deactivateExpenseType(
          companyId: _companyId,
          expenseTypeId: _typeId,
          actorRole: 'owner',
        );

        expect(result, isA<Success>());
        expect(result.dataOrNull?.isActive, isFalse);
        expect(operations, ['get_by_id', 'deactivate', 'audit']);
        expect(
          auditRepository.lastData?.description,
          'expense_type_deactivated',
        );
        expect(auditRepository.lastData?.oldValues?['is_active'], isTrue);
        expect(auditRepository.lastData?.newValues?['is_active'], isFalse);
      },
    );

    test(
      'reactivate snapshots state, mutates, then audits lifecycle',
      () async {
        final operations = <String>[];
        final dataSource = _FakeExpenseTypesRemoteDataSource(
          operations: operations,
          snapshotModel: _model(isActive: false),
        );
        final auditRepository = _FakeAuditRepository(operations: operations);
        final repository = _repository(dataSource, auditRepository);

        final result = await repository.reactivateExpenseType(
          companyId: _companyId,
          expenseTypeId: _typeId,
          actorRole: 'accountant',
        );

        expect(result, isA<Success>());
        expect(result.dataOrNull?.isActive, isTrue);
        expect(operations, ['get_by_id', 'reactivate', 'audit']);
        expect(
          auditRepository.lastData?.description,
          'expense_type_reactivated',
        );
        expect(auditRepository.lastData?.oldValues?['is_active'], isFalse);
        expect(auditRepository.lastData?.newValues?['is_active'], isTrue);
      },
    );

    test('does not audit when create mutation fails', () async {
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

    test('does not audit when deactivate mutation fails', () async {
      final operations = <String>[];
      final dataSource = _FakeExpenseTypesRemoteDataSource(
        operations: operations,
        deactivateError: StateError('internal'),
      );
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.deactivateExpenseType(
        companyId: _companyId,
        expenseTypeId: _typeId,
        actorRole: 'admin',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(operations, ['get_by_id', 'deactivate']);
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

class _FakeExpenseTypesRemoteDataSource
    implements ExpenseTypesRemoteDataSource {
  final List<String>? operations;
  final Object? addError;
  final Object? getByIdError;
  final Object? deactivateError;
  final ExpenseTypeModel? snapshotModel;
  String? lastListCompanyId;
  String? lastActiveCompanyId;

  _FakeExpenseTypesRemoteDataSource({
    this.operations,
    this.addError,
    this.getByIdError,
    this.deactivateError,
    this.snapshotModel,
  });

  @override
  Future<List<ExpenseTypeModel>> getExpenseTypes({
    required String companyId,
  }) async {
    lastListCompanyId = companyId;
    return [_model()];
  }

  @override
  Future<List<ExpenseTypeModel>> getActiveExpenseTypes({
    required String companyId,
  }) async {
    lastActiveCompanyId = companyId;
    return [_model()];
  }

  @override
  Future<ExpenseTypeModel> getExpenseTypeById({
    required String companyId,
    required String expenseTypeId,
  }) async {
    operations?.add('get_by_id');
    if (getByIdError != null) throw getByIdError!;
    return snapshotModel ?? _model();
  }

  @override
  Future<ExpenseTypeModel> addExpenseType({
    required ExpenseTypeWriteData data,
  }) async {
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
    if (deactivateError != null) throw deactivateError!;
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
  final Failure? failure;
  AuditLogWriteData? lastData;

  _FakeAuditRepository({this.operations, this.failure});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    if (failure != null) return FailureResult<void>(failure!);
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
