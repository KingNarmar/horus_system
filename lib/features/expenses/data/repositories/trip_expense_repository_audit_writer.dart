import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/trip_expense_mapper.dart';
import '../models/trip_expense_model.dart';

const _entityDisplayName = 'Trip expense';
const _createdEvent = 'trip_expense_created';
const _updatedEvent = 'trip_expense_updated';

final class TripExpenseRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const TripExpenseRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required String companyId,
    required String tripId,
    required TripExpenseModel model,
    required double tripTotalExpenses,
    required String actorRole,
  }) {
    return _write(
      companyId: companyId,
      tripId: tripId,
      model: model,
      tripTotalExpenses: tripTotalExpenses,
      actorRole: actorRole,
      action: AuditAction.created,
      event: _createdEvent,
    );
  }

  Future<Failure?> writeUpdated({
    required String companyId,
    required String tripId,
    required TripExpenseModel? oldModel,
    required TripExpenseModel model,
    required double tripTotalExpenses,
    required String actorRole,
  }) {
    return _write(
      companyId: companyId,
      tripId: tripId,
      model: model,
      tripTotalExpenses: tripTotalExpenses,
      actorRole: actorRole,
      action: AuditAction.updated,
      event: _updatedEvent,
      oldValues: oldModel?.toAuditValues(),
    );
  }

  Future<Failure?> _write({
    required String companyId,
    required String tripId,
    required TripExpenseModel model,
    required double tripTotalExpenses,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final result = await _createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.trips,
          entityType: AuditEntityType.trip,
          entityId: tripId,
          entityDisplayName: _entityDisplayName,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
          metadata: {
            'expense_id': model.id,
            'expense_name': model.expenseName,
            'amount': model.amount,
            'paid_by': model.paidBy,
            'trip_total_expenses': tripTotalExpenses,
          },
        ),
      ),
    );

    return result.failureOrNull;
  }
}
