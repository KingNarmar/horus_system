import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_action.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_log_write_data.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_write_data.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_data_source.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';

const _customerCreatedEvent = 'customer_created';
const _customerUpdatedEvent = 'customer_updated';
const _customerDeactivatedEvent = 'customer_deactivated';
const _customerReactivatedEvent = 'customer_reactivated';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;

  const CustomersRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  });

  @override
  Future<Result<List<Customer>>> getCustomers({required String companyId}) {
    return _guard(() async {
      final normalizedCompanyId = companyId.trim();
      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<List<Customer>>(
          ValidationFailure(
            code: FailureCodes.validationCompanyIdRequired,
            message: 'Company id is required.',
          ),
        );
      }

      final models = await remoteDataSource.getCustomers(
        companyId: normalizedCompanyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addCustomer(data: data);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.created,
        description: _customerCreatedEvent,
      );
    });
  }

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCustomerById(
        companyId: data.companyId,
        customerId: customerId,
      );
      final model = await remoteDataSource.updateCustomer(
        customerId: customerId,
        data: data,
      );
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: AuditAction.updated,
        description: _customerUpdatedEvent,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  @override
  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      customerId: customerId,
      actorRole: actorRole,
      action: AuditAction.deactivated,
      description: _customerDeactivatedEvent,
      mutate: remoteDataSource.deactivateCustomer,
    );
  }

  @override
  Future<Result<Customer>> reactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      customerId: customerId,
      actorRole: actorRole,
      action: AuditAction.reactivated,
      description: _customerReactivatedEvent,
      mutate: remoteDataSource.reactivateCustomer,
    );
  }

  Future<Result<Customer>> _changeStatus({
    required String companyId,
    required String customerId,
    required String actorRole,
    required AuditAction action,
    required String description,
    required Future<CustomerModel> Function({
      required String companyId,
      required String customerId,
    })
    mutate,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCustomerById(
        companyId: companyId,
        customerId: customerId,
      );
      final model = await mutate(companyId: companyId, customerId: customerId);
      return _withAudit(
        model: model,
        actorRole: actorRole,
        action: action,
        description: description,
        oldValues: oldModel.toAuditValues(),
      );
    });
  }

  Future<Result<Customer>> _withAudit({
    required CustomerModel model,
    required String actorRole,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
  }) async {
    final auditFailure = await _writeCustomerAudit(
      companyId: model.companyId,
      actorRole: actorRole,
      entityId: model.id,
      entityDisplayName: model.name,
      action: action,
      description: description,
      oldValues: oldValues,
      newValues: model.toAuditValues(),
    );

    if (auditFailure != null) {
      return FailureResult(auditFailure);
    }

    return Success(model.toEntity());
  }

  Future<Failure?> _writeCustomerAudit({
    required String companyId,
    required String actorRole,
    required String entityId,
    required String entityDisplayName,
    required AuditAction action,
    required String description,
    Map<String, Object?>? oldValues,
    Map<String, Object?>? newValues,
  }) async {
    final result = await createAuditLogUseCase(
      CreateAuditLogParams(
        data: AuditLogWriteData(
          companyId: companyId,
          actorRole: actorRole,
          module: AuditModule.customers,
          entityType: AuditEntityType.customer,
          entityId: entityId,
          entityDisplayName: entityDisplayName,
          action: action,
          description: description,
          oldValues: oldValues,
          newValues: newValues,
        ),
      ),
    );
    return result.failureOrNull;
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
