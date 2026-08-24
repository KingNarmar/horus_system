import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../mappers/payment_method_mapper.dart';
import '../models/payment_method_model.dart';

const _paymentMethodCreatedEvent = 'payment_method_created';
const _paymentMethodUpdatedEvent = 'payment_method_updated';
const _paymentMethodDeactivatedEvent = 'payment_method_deactivated';
const _paymentMethodReactivatedEvent = 'payment_method_reactivated';

final class PaymentMethodRepositoryAuditWriter {
  final CreateAuditLogUseCase _createAuditLogUseCase;

  const PaymentMethodRepositoryAuditWriter(this._createAuditLogUseCase);

  Future<Failure?> writeCreated({
    required PaymentMethodModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.created,
      event: _paymentMethodCreatedEvent,
    );
  }

  Future<Failure?> writeUpdated({
    required PaymentMethodModel oldModel,
    required PaymentMethodModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.updated,
      event: _paymentMethodUpdatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeDeactivated({
    required PaymentMethodModel oldModel,
    required PaymentMethodModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      event: _paymentMethodDeactivatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> writeReactivated({
    required PaymentMethodModel oldModel,
    required PaymentMethodModel model,
    required String actorRole,
  }) {
    return _write(
      model: model,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      event: _paymentMethodReactivatedEvent,
      oldValues: oldModel.toAuditValues(),
    );
  }

  Future<Failure?> _write({
    required PaymentMethodModel model,
    required String actorRole,
    required AuditAction action,
    required String event,
    Map<String, Object?>? oldValues,
  }) async {
    final result = await _createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: model.companyId,
          actorRole: actorRole,
          module: AuditModule.companySettings,
          entityType: AuditEntityType.paymentMethod,
          entityId: model.id,
          entityDisplayName: model.name,
          action: action,
          description: event,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
        ),
      ),
    );

    return result.failureOrNull;
  }
}
