import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_write_data.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_data_source.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';
import 'customer_repository_audit_writer.dart';
import 'customer_repository_failure_mapper.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final CustomerRepositoryFailureMapper _failureMapper;

  const CustomersRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const CustomerRepositoryFailureMapper();

  CustomerRepositoryAuditWriter get _auditWriter {
    return CustomerRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<Customer>>> getCustomers({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getCustomers(companyId: companyId);
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
      final auditFailure = await _auditWriter.writeCreated(
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<Customer>(auditFailure);
      }
      return Success(model.toEntity());
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
      final auditFailure = await _auditWriter.writeUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<Customer>(auditFailure);
      }
      return Success(model.toEntity());
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
      mutate: remoteDataSource.deactivateCustomer,
      writeAudit: _auditWriter.writeDeactivated,
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
      mutate: remoteDataSource.reactivateCustomer,
      writeAudit: _auditWriter.writeReactivated,
    );
  }

  Future<Result<Customer>> _changeStatus({
    required String companyId,
    required String customerId,
    required String actorRole,
    required Future<CustomerModel> Function({
      required String companyId,
      required String customerId,
    })
    mutate,
    required Future<Failure?> Function({
      required CustomerModel oldModel,
      required CustomerModel model,
      required String actorRole,
    })
    writeAudit,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCustomerById(
        companyId: companyId,
        customerId: customerId,
      );
      final model = await mutate(companyId: companyId, customerId: customerId);
      final auditFailure = await writeAudit(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<Customer>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
