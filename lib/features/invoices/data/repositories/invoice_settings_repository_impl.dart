import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/entities/company_invoice_settings.dart';
import '../../domain/failures/invoice_failure_codes.dart';
import '../../domain/repositories/invoice_settings_repository.dart';
import '../../domain/value_objects/invoice_prefix.dart';
import '../datasources/invoice_settings_remote_data_source.dart';
import '../mappers/company_invoice_settings_mapper.dart';
import '../mappers/invoices_failure_mapper.dart';

final class InvoiceSettingsRepositoryImpl implements InvoiceSettingsRepository {
  final InvoiceSettingsRemoteDataSource _remoteDataSource;

  const InvoiceSettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<CompanyInvoiceSettings?>> get({
    required String companyId,
  }) async {
    try {
      final model = await _remoteDataSource.get(companyId: companyId);
      return Success(model?.toEntity());
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        InvoicesFailureMapper.fromPostgrest(
          error,
          permissionCode: FailureCodes.permissionInvoicesView,
        ),
      );
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }

  @override
  Future<Result<CompanyInvoiceSettings>> update({
    required String companyId,
    required InvoicePrefix prefix,
  }) async {
    try {
      final model = await _remoteDataSource.update(
        companyId: companyId,
        prefix: prefix,
      );
      return Success(model.toEntity());
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        InvoicesFailureMapper.fromPostgrest(
          error,
          permissionCode: InvoiceFailureCodes.permissionSettingsManagement,
        ),
      );
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
