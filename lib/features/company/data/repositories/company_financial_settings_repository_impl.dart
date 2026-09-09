import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../../domain/repositories/company_financial_settings_repository.dart';
import '../datasources/company_financial_settings_remote_data_source.dart';
import '../mappers/company_mapper.dart';
import '../mappers/company_regional_settings_failure_mapper.dart';

final class CompanyFinancialSettingsRepositoryImpl
    implements CompanyFinancialSettingsRepository {
  final CompanyFinancialSettingsRemoteDataSource _remoteDataSource;

  const CompanyFinancialSettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  }) async {
    try {
      final model = await _remoteDataSource.update(
        companyId: companyId,
        baseCurrencyCode: baseCurrencyCode,
        baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      );
      return Success(model.toEntity());
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        CompanyRegionalSettingsFailureMapper.fromPostgrest(error),
      );
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
