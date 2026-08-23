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
import 'package:horus_system/features/expenses/data/datasources/trip_expenses_remote_data_source.dart';
import 'package:horus_system/features/expenses/data/models/trip_expense_model.dart';
import 'package:horus_system/features/expenses/data/repositories/trip_expense_repo_impl.dart';
import 'package:horus_system/features/expenses/domain/entities/expense_type_option.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('TripExpensesRepositoryImpl', () {
    test('adds expense, reads DB-owned total, then writes audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = TripExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, _expenseId);
      expect(operations, ['add_expense', 'read_total', 'audit']);
      expect(remoteDataSource.lastTotalReadCompanyId, _companyId);
      expect(remoteDataSource.lastTotalReadTripId, _tripId);
      expect(auditRepository.logs.single.description, 'trip_expense_created');
      expect(
        auditRepository.logs.single.metadata?['trip_total_expenses'],
        _tripTotal,
      );
    });

    test('does not read total or audit when mutation fails', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        operations: operations,
        addError: Exception('mutation failed'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = TripExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(operations, ['add_expense']);
      expect(auditRepository.logs, isEmpty);
    });

    test('does not write audit when persisted total read fails', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        operations: operations,
        totalReadError: Exception('total read failed'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = TripExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(operations, ['add_expense', 'read_total']);
      expect(auditRepository.logs, isEmpty);
    });

    test('propagates audit failure after mutation and total read', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeTripExpensesRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(
        operations: operations,
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = TripExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(operations, ['add_expense', 'read_total', 'audit']);
    });

    test(
      'updates after old snapshot lookup and audits persisted total last',
      () async {
        final operations = <String>[];
        final remoteDataSource = _FakeTripExpensesRemoteDataSource(
          operations: operations,
        );
        final auditRepository = _FakeAuditLogRepository(operations: operations);
        final repository = TripExpensesRepositoryImpl(
          remoteDataSource: remoteDataSource,
          createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
        );

        final result = await repository.updateTripExpense(
          id: _expenseId,
          data: _writeData(amount: 175),
          actorRole: 'accountant',
        );

        expect(result, isA<Success>());
        expect(result.dataOrNull?.amount, 175);
        expect(operations, [
          'get_expenses',
          'update_expense',
          'read_total',
          'audit',
        ]);
        expect(remoteDataSource.lastListCompanyId, _companyId);
        expect(remoteDataSource.lastListTripId, _tripId);
        expect(remoteDataSource.lastTotalReadCompanyId, _companyId);
        expect(remoteDataSource.lastTotalReadTripId, _tripId);
        expect(auditRepository.logs.single.description, 'trip_expense_updated');
        expect(auditRepository.logs.single.oldValues?['amount'], 100);
        expect(auditRepository.logs.single.newValues?['amount'], 175);
        expect(
          auditRepository.logs.single.metadata?['trip_total_expenses'],
          _tripTotal,
        );
      },
    );

    test('forwards company and trip scope when loading expenses', () async {
      final remoteDataSource = _FakeTripExpensesRemoteDataSource();
      final repository = TripExpensesRepositoryImpl(
        remoteDataSource: remoteDataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
      );

      final result = await repository.getTripExpenses(
        companyId: _companyId,
        tripId: _tripId,
      );

      expect(result, isA<Success>());
      expect(remoteDataSource.lastListCompanyId, _companyId);
      expect(remoteDataSource.lastListTripId, _tripId);
    });
  });
}

const _companyId = 'company-1';
const _tripId = 'trip-1';
const _expenseId = 'expense-1';
const _expenseTypeId = 'expense-type-1';
const _tripTotal = 300.0;

TripExpenseWriteData _writeData({double amount = 125.5}) {
  return TripExpenseWriteData(
    companyId: _companyId,
    tripId: _tripId,
    expenseTypeId: _expenseTypeId,
    expenseName: 'Fuel',
    amount: amount,
    paidBy: TripExpensePaidBy.company,
    expenseDate: DateTime.utc(2026, 8, 22),
    notes: 'note',
  );
}

TripExpenseModel _expenseModel({double amount = 100}) {
  return TripExpenseModel(
    id: _expenseId,
    companyId: _companyId,
    tripId: _tripId,
    expenseTypeId: _expenseTypeId,
    expenseName: 'Fuel',
    amount: amount,
    paidBy: 'company',
    expenseDate: DateTime.utc(2026, 8, 22),
    notes: 'note',
    expenseTypeName: 'Fuel',
  );
}

class _FakeTripExpensesRemoteDataSource
    implements TripExpensesRemoteDataSource {
  final List<String>? operations;
  final Object? addError;
  final Object? totalReadError;
  String? lastListCompanyId;
  String? lastListTripId;
  String? lastTotalReadCompanyId;
  String? lastTotalReadTripId;

  _FakeTripExpensesRemoteDataSource({
    this.operations,
    this.addError,
    this.totalReadError,
  });

  @override
  Future<List<TripExpenseModel>> getTripExpenses({
    required String companyId,
    required String tripId,
  }) async {
    operations?.add('get_expenses');
    lastListCompanyId = companyId;
    lastListTripId = tripId;
    return [_expenseModel()];
  }

  @override
  Future<List<ExpenseTypeOption>> getExpenseTypes({
    required String companyId,
  }) async {
    return const [];
  }

  @override
  Future<TripExpenseModel> addTripExpense({
    required TripExpenseWriteData data,
  }) async {
    operations?.add('add_expense');
    if (addError != null) throw addError!;
    return _expenseModel(amount: data.amount);
  }

  @override
  Future<TripExpenseModel> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
  }) async {
    operations?.add('update_expense');
    return _expenseModel(amount: data.amount);
  }

  @override
  Future<double> getTripTotalExpenses({
    required String companyId,
    required String tripId,
  }) async {
    operations?.add('read_total');
    lastTotalReadCompanyId = companyId;
    lastTotalReadTripId = tripId;
    if (totalReadError != null) throw totalReadError!;
    return _tripTotal;
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure, this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    if (failure != null) return FailureResult<void>(failure!);
    logs.add(data);
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
