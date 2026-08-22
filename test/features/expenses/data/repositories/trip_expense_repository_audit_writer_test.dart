import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/expenses/data/models/trip_expense_model.dart';
import 'package:horus_system/features/expenses/data/repositories/trip_expense_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('TripExpenseRepositoryAuditWriter', () {
    test('preserves created audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = TripExpenseRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeCreated(
        companyId: _companyId,
        tripId: _tripId,
        model: _expenseModel(),
        tripTotalExpenses: _tripTotal,
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.companyId, _companyId);
      expect(data.actorRole, 'accountant');
      expect(data.module, AuditModule.trips);
      expect(data.entityType, AuditEntityType.trip);
      expect(data.entityId, _tripId);
      expect(data.entityDisplayName, 'Trip expense');
      expect(data.action, AuditAction.created);
      expect(data.description, 'trip_expense_created');
      expect(data.oldValues, isNull);
      expect(data.newValues?['amount'], 125.5);
      expect(data.newValues?['expense_name'], 'Fuel');
      expect(data.metadata?['expense_id'], _expenseId);
      expect(data.metadata?['expense_name'], 'Fuel');
      expect(data.metadata?['amount'], 125.5);
      expect(data.metadata?['paid_by'], 'driver_cash');
      expect(data.metadata?['trip_total_expenses'], _tripTotal);
    });

    test('preserves updated old and new audit snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = TripExpenseRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeUpdated(
        companyId: _companyId,
        tripId: _tripId,
        oldModel: _expenseModel(amount: 100),
        model: _expenseModel(amount: 175),
        tripTotalExpenses: 350,
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.updated);
      expect(data.description, 'trip_expense_updated');
      expect(data.oldValues?['amount'], 100);
      expect(data.newValues?['amount'], 175);
      expect(data.metadata?['expense_id'], _expenseId);
      expect(data.metadata?['trip_total_expenses'], 350);
    });

    test(
      'keeps null old snapshot when expense lookup does not find a row',
      () async {
        final repository = _CapturingAuditLogRepository();
        final writer = TripExpenseRepositoryAuditWriter(
          CreateAuditLogUseCase(repository),
        );

        final failure = await writer.writeUpdated(
          companyId: _companyId,
          tripId: _tripId,
          oldModel: null,
          model: _expenseModel(amount: 175),
          tripTotalExpenses: 350,
          actorRole: 'accountant',
        );

        expect(failure, isNull);
        expect(repository.logs.single.oldValues, isNull);
      },
    );
  });
}

const _companyId = 'company-1';
const _tripId = 'trip-1';
const _expenseId = 'expense-1';
const _expenseTypeId = 'expense-type-1';
const _tripTotal = 300.0;

TripExpenseModel _expenseModel({double amount = 125.5}) {
  return TripExpenseModel(
    id: _expenseId,
    companyId: _companyId,
    tripId: _tripId,
    expenseTypeId: _expenseTypeId,
    expenseName: 'Fuel',
    amount: amount,
    paidBy: 'driver_cash',
    expenseDate: DateTime.utc(2026, 8, 22),
    notes: 'note',
    expenseTypeName: 'Fuel',
    createdAt: DateTime.utc(2026, 8, 22, 9),
    updatedAt: DateTime.utc(2026, 8, 22, 10),
  );
}

class _CapturingAuditLogRepository implements AuditLogRepository {
  final List<AuditLogWriteData> logs = [];

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
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
