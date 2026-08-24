import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_invoice_settings.dart';
import '../../domain/failures/invoice_failure_codes.dart';
import '../../domain/repositories/invoice_settings_repository.dart';
import '../../domain/value_objects/invoice_prefix.dart';
import '../datasources/invoice_settings_remote_data_source.dart';
import '../mappers/company_invoice_settings_mapper.dart';
import 'invoices_repository_failure_mapper.dart';

final class InvoiceSettingsRepositoryImpl implements InvoiceSettingsRepository {
  final InvoiceSettingsRemoteDataSource _remoteDataSource;

  const InvoiceSettingsRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = InvoicesRepositoryFailureMapper();

  @override
  Future<Result<CompanyInvoiceSettings?>> get({
    required String companyId,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesView,
      action: () async {
        final model = await _remoteDataSource.get(companyId: companyId);
        return model?.toEntity();
      },
    );
  }

  @override
  Future<Result<CompanyInvoiceSettings>> update({
    required String companyId,
    required InvoicePrefix prefix,
  }) {
    return _execute(
      permissionCode: InvoiceFailureCodes.permissionSettingsManagement,
      action: () async {
        final model = await _remoteDataSource.update(
          companyId: companyId,
          prefix: prefix,
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
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } on PostgrestException catch (error) {
      return FailureResult(
        _failureMapper.fromPostgrest(
          error,
          permissionCode: permissionCode,
        ),
      );
    } on FormatException catch (error) {
      return FailureResult(_failureMapper.fromFormatException(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
