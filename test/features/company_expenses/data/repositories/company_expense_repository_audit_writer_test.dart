import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/company_expenses/data/models/company_expense_model.dart';
import 'package:horus_system/features/company_expenses/data/repositories/company_expense_repository_audit_writer.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyExpenseRepositoryAuditWriter', () {
    test('preserves created audit contract', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = CompanyExpenseRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeCreated(
        model: _expenseModel(),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.companyId, _companyId);
      expect(data.actorRole, 'accountant');
      expect(data.module, AuditModule.expenses);
      expect(data.entityType, AuditEntityType.expense);
      expect(data.entityId, _expenseId);
      expect(data.entityDisplayName, 'company_expense');
      expect(data.action, AuditAction.created);
      expect(data.description, 'company_expense_created');
      expect(data.oldValues, isNull);
      expect(data.newValues?['amount'], 125.5);
      expect(data.newValues?['category_id'], _categoryId);
      expect(data.metadata?['audit_event'], 'company_expense_created');
      expect(data.metadata?['amount'], 125.5);
      expect(data.metadata?['category_id'], _categoryId);
      expect(data.metadata?['driver_id'], _driverId);
      expect(data.metadata?['tractor_head_id'], _tractorHeadId);
      expect(data.metadata?['trailer_id'], _trailerId);
      expect(data.metadata?['trip_id'], _tripId);
    });

    test('preserves updated old and new audit snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = CompanyExpenseRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeUpdated(
        oldModel: _expenseModel(amount: 100),
        model: _expenseModel(amount: 150),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.updated);
      expect(data.description, 'company_expense_updated');
      expect(data.oldValues?['amount'], 100);
      expect(data.newValues?['amount'], 150);
      expect(data.metadata?['audit_event'], 'company_expense_updated');
      expect(data.metadata?['amount'], 150);
    });

    test('preserves voided old and new audit snapshots', () async {
      final repository = _CapturingAuditLogRepository();
      final writer = CompanyExpenseRepositoryAuditWriter(
        CreateAuditLogUseCase(repository),
      );

      final failure = await writer.writeVoided(
        oldModel: _expenseModel(),
        model: _expenseModel(isVoided: true, voidReason: 'duplicate'),
        actorRole: 'accountant',
      );

      expect(failure, isNull);
      final data = repository.logs.single;
      expect(data.action, AuditAction.statusChanged);
      expect(data.description, 'company_expense_voided');
      expect(data.oldValues?['is_voided'], isFalse);
      expect(data.newValues?['is_voided'], isTrue);
      expect(data.newValues?['void_reason'], 'duplicate');
      expect(data.metadata?['audit_event'], 'company_expense_voided');
    });
  });
}

const _companyId = 'company-1';
const _expenseId = 'expense-1';
const _categoryId = 'category-1';
const _driverId = 'driver-1';
const _tractorHeadId = 'tractor-1';
const _trailerId = 'trailer-1';
const _tripId = 'trip-1';

CompanyExpenseModel _expenseModel({
  double amount = 125.5,
  bool isVoided = false,
  String? voidReason,
}) {
  return CompanyExpenseModel(
    id: _expenseId,
    companyId: _companyId,
    categoryId: _categoryId,
    driverId: _driverId,
    tractorHeadId: _tractorHeadId,
    trailerId: _trailerId,
    tripId: _tripId,
    amount: amount,
    expenseDate: DateTime.utc(2026, 8, 19),
    referenceNumber: 'REF-1',
    notes: 'note',
    isVoided: isVoided,
    voidReason: voidReason,
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
