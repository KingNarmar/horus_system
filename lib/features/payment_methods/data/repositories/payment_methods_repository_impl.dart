import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_write_data.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../datasources/payment_methods_remote_data_source.dart';
import '../mappers/payment_method_mapper.dart';
import '../models/payment_method_model.dart';

const _paymentMethodCreatedEvent = 'payment_method_created';
const _paymentMethodUpdatedEvent = 'payment_method_updated';
const _paymentMethodDeactivatedEvent = 'payment_method_deactivated';
const _paymentMethodReactivatedEvent = 'payment_method_reactivated';

class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  final PaymentMethodsRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const PaymentMethodsRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) {
    return _guard(() async {
      final normalizedCompanyId = companyId.trim();
      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<List<PaymentMethod>>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        );
      }

      final models = await remoteDataSource.getPaymentMethods(
        companyId: normalizedCompanyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    }, permissionCode: FailureCodes.permissionPaymentMethodsView);
  }

  @override
  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  }) {
    return _guard(() async {
      final normalizedCompanyId = companyId.trim();
      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<List<PaymentMethod>>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        );
      }

      final models = await remoteDataSource.getActivePaymentMethods(
        companyId: normalizedCompanyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    }, permissionCode: FailureCodes.permissionPaymentMethodsView);
  }

  @override
  Future<Result<PaymentMethod>> addPaymentMethod({
    required PaymentMethodWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addPaymentMethod(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.created,
        description: _paymentMethodCreatedEvent,
      );
    }, permissionCode: FailureCodes.permissionPaymentMethodsManagement);
  }

  @override
  Future<Result<PaymentMethod>> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getPaymentMethodById(
        companyId: data.companyId,
        paymentMethodId: paymentMethodId,
      );
      final model = await remoteDataSource.updatePaymentMethod(
        paymentMethodId: paymentMethodId,
        data: data,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.updated,
        description: _paymentMethodUpdatedEvent,
        oldValues: oldModel.toAuditValues(),
      );
    }, permissionCode: FailureCodes.permissionPaymentMethodsManagement);
  }

  @override
  Future<Result<PaymentMethod>> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      paymentMethodId: paymentMethodId,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      description: _paymentMethodDeactivatedEvent,
      mutate: remoteDataSource.deactivatePaymentMethod,
    );
  }

  @override
  Future<Result<PaymentMethod>> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      paymentMethodId: paymentMethodId,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      description: _paymentMethodReactivatedEvent,
      mutate: remoteDataSource.reactivatePaymentMethod,
    );
  }

  Future<Result<PaymentMethod>> _changeStatus({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
    required AuditAction action,
    required String description,
    required Future<PaymentMethodModel> Function({
      required String companyId,
      required String paymentMethodId,
    })
    mutate,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getPaymentMethodById(
        companyId: companyId,
        paymentMethodId: paymentMethodId,
      );
      final model = await mutate(
        companyId: companyId,
        paymentMethodId: paymentMethodId,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: action,
        description: description,
        oldValues: oldModel.toAuditValues(),
      );
    }, permissionCode: FailureCodes.permissionPaymentMethodsManagement);
  }

  Future<Result<PaymentMethod>> _withAudit({
    required PaymentMethodModel model,
    required String actorRole,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
  }) async {
    final auditResult = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: model.companyId,
          actorRole: actorRole,
          module: AuditModule.companySettings,
          entityType: AuditEntityType.paymentMethod,
          entityId: model.id,
          entityDisplayName: model.name,
          action: action,
          description: description,
          oldValues: oldValues,
          newValues: model.toAuditValues(),
        ),
      ),
    );

    final auditFailure = auditResult.failureOrNull;
    if (auditFailure != null) {
      return FailureResult(auditFailure);
    }

    return Success(model.toEntity());
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function() action, {
    required String permissionCode,
  }) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_mapPostgrestException(error, permissionCode));
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  Failure _mapPostgrestException(
    PostgrestException error,
    String permissionCode,
  ) {
    return switch (error.code) {
      '23505' => const ConflictFailure(
        code: FailureCodes.conflictPaymentMethodDuplicateName,
        message: 'A payment method with this name already exists.',
      ),
      'PGRST116' => const NotFoundFailure(
        code: FailureCodes.paymentMethodNotFound,
        message: 'Payment method was not found.',
      ),
      '42501' => PermissionFailure(
        code: permissionCode,
        message: 'Payment method access is not allowed.',
      ),
      _ => ServerFailure(
        code: FailureCodes.serverError,
        message: error.message,
      ),
    };
  }
}
