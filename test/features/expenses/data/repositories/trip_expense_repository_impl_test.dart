import 'package:horus_system/core/errors/common_failures.dart';
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
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_write_data.dart';
import 'package:test/test.dart';

void main() {
  group('TripExpensesRepositoryImpl', () {
    test('forwards company and trip scope when loading expenses', () async {
      final dataSource = _FakeTripExpensesRemoteDataSource();
      final repository = _repository(dataSource);
      final result = await repository.getTripExpenses(
        companyId: _companyId,
        tripId: _tripId,
      );
      expect(result, isA<Success>());
      expect(dataSource.lastListCompanyId, _companyId);
      expect(dataSource.lastListTripId, _tripId);
    });

    test('adds expense, reads DB total, then audits', () async {
      final operations = <String>[];
      final dataSource = _FakeTripExpensesRemoteDataSource(operations: operations);
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(operations, ['add', 'read_total', 'audit']);
      expect(auditRepository.lastData?.description, 'trip_expense_created');
      expect(auditRepository.lastData?.companyId, _companyId);
    });

    test('updates after snapshot lookup and audits old/new values', () async {
      final operations = <String>[];
      final dataSource = _FakeTripExpensesRemoteDataSource(operations: operations);
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.updateTripExpense(
        id: _expenseId,
        data: _writeData(amount: 175),
        actorRole: 'admin',
      );

      expect(result, isA<Success>());
      expect(operations, ['list', 'update', 'read_total', 'audit']);
      expect(auditRepository.lastData?.oldValues?['amount'], 100);
      expect(auditRepository.lastData?.newValues?['amount'], 175);
    });

    test('sanitizes mutation failure and skips total/audit', () async {
      final operations = <String>[];
      final dataSource = _FakeTripExpensesRemoteDataSource(
        operations: operations,
        addError: StateError('internal detail'),
      );
      final auditRepository = _FakeAuditRepository(operations: operations);
      final repository = _repository(dataSource, auditRepository);

      final result = await repository.addTripExpense(
        data: _writeData(),
        actorRole: 'owner',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add']);
      expect(auditRepository.lastData, isNull);
    });
  });
}

const _companyId = 'company-1';
const _tripId = 'trip-1';
const _expenseId = 'expense-1';
const _expenseTypeId = 'expense-type-1';

TripExpensesRepositoryImpl _repository(
  _FakeTripExpensesRemoteDataSource dataSource, [
  _FakeAuditRepository? auditRepository,
]) {
  return TripExpensesRepositoryImpl(
    remoteDataSource: dataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditRepository(),
    ),
  );
}

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

TripExpenseModel _model({double amount = 100}) {
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

class _FakeTripExpensesRemoteDataSource implements TripExpensesRemoteDataSource {
  final List<String>? operations;
  final Object? addError;
  String? lastListCompanyId;
  String? lastListTripId;

  _FakeTripExpensesRemoteDataSource({this.operations, this.addError});

  @override
  Future<List<TripExpenseModel>> getTripExpenses({
    required String companyId,
    required String tripId,
  }) async {
    operations?.add('list');
    lastListCompanyId = companyId;
    lastListTripId = tripId;
    return [_model()];
  }

  @override
  Future<TripExpenseModel> addTripExpense({required TripExpenseWriteData data}) async {
    operations?.add('add');
    if (addError != null) throw addError!;
    return _model(amount: data.amount);
  }

  @override
  Future<TripExpenseModel> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
  }) async {
    operations?.add('update');
    return _model(amount: data.amount);
  }

  @override
  Future<double> getTripTotalExpenses({
    required String companyId,
    required String tripId,
  }) async {
    operations?.add('read_total');
    return 300;
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
