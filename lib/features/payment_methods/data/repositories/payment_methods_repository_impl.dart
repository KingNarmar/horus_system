import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_write_data.dart';
import '../../domain/repositories/payment_methods_repository.dart';
import '../datasources/payment_methods_remote_data_source.dart';
import '../mappers/payment_method_mapper.dart';
import 'payment_method_repository_audit_writer.dart';
import 'payment_method_repository_failure_mapper.dart';

class PaymentMethodsRepositoryImpl implements PaymentMethodsRepository {
  final PaymentMethodsRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final PaymentMethodRepositoryFailureMapper _failureMapper;

  const PaymentMethodsRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const PaymentMethodRepositoryFailureMapper();

  PaymentMethodRepositoryAuditWriter get _auditWriter {
    return PaymentMethodRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getPaymentMethods(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    }, permissionCode: FailureCodes.permissionPaymentMethodsView);
  }

  @override
  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getActivePaymentMethods(
        companyId: companyId,
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
      final auditFailure = await _auditWriter.writeCreated(
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<PaymentMethod>(auditFailure);
      }
      return Success(model.toEntity());
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
      final auditFailure = await _auditWriter.writeUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<PaymentMethod>(auditFailure);
      }
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionPaymentMethodsManagement);
  }

  @override
  Future<Result<PaymentMethod>> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getPaymentMethodById(
        companyId: companyId,
        paymentMethodId: paymentMethodId,
      );
      final model = await remoteDataSource.deactivatePaymentMethod(
        companyId: companyId,
        paymentMethodId: paymentMethodId,
      );
      final auditFailure = await _auditWriter.writeDeactivated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<PaymentMethod>(auditFailure);
      }
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionPaymentMethodsManagement);
  }

  @override
  Future<Result<PaymentMethod>> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getPaymentMethodById(
        companyId: companyId,
        paymentMethodId: paymentMethodId,
      );
      final model = await remoteDataSource.reactivatePaymentMethod(
        companyId: companyId,
        paymentMethodId: paymentMethodId,
      );
      final auditFailure = await _auditWriter.writeReactivated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<PaymentMethod>(auditFailure);
      }
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionPaymentMethodsManagement);
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function() action, {
    required String permissionCode,
  }) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        _failureMapper.fromPostgrest(error, permissionCode: permissionCode),
      );
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
