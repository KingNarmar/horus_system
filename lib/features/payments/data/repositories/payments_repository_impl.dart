import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/entities/payment.dart';
import '../../domain/failures/payment_failure_codes.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_remote_data_source.dart';
import '../mappers/payment_mapper.dart';
import '../mappers/payments_failure_mapper.dart';

final class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsRemoteDataSource _remoteDataSource;

  const PaymentsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<List<Payment>>> getPayments({required String companyId}) {
    return _execute(
      permissionCode: PaymentFailureCodes.permissionView,
      action: () async {
        final models = await _remoteDataSource.getPayments(companyId: companyId);
        return models.map((model) => model.toEntity()).toList(growable: false);
      },
    );
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) {
    return _execute(
      permissionCode: PaymentFailureCodes.permissionView,
      action: () async {
        final models = await _remoteDataSource.getPaymentsForInvoice(
          companyId: companyId,
          invoiceId: invoiceId,
        );
        return models.map((model) => model.toEntity()).toList(growable: false);
      },
    );
  }

  @override
  Future<Result<Payment>> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  }) {
    return _execute(
      permissionCode: PaymentFailureCodes.permissionManage,
      action: () async {
        final model = await _remoteDataSource.registerPayment(
          companyId: companyId,
          invoiceId: invoiceId,
          paymentMethodId: paymentMethodId,
          paymentDate: paymentDate,
          amount: amount,
          referenceNumber: referenceNumber,
          notes: notes,
        );
        return model.toEntity();
      },
    );
  }

  Future<Result<T>> _execute<T>({
    required String permissionCode,
    required Future<T> Function() action,
  }) async {
    try {
      return Success(await action());
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        PaymentsFailureMapper.fromPostgrest(
          error,
          permissionCode: permissionCode,
        ),
      );
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
