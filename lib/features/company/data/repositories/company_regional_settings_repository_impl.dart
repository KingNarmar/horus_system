import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../../domain/repositories/company_regional_settings_repository.dart';
import '../datasources/company_regional_settings_remote_data_source.dart';
import '../mappers/company_mapper.dart';
import '../mappers/company_regional_settings_failure_mapper.dart';

final class CompanyRegionalSettingsRepositoryImpl
    implements CompanyRegionalSettingsRepository {
  final CompanyRegionalSettingsRemoteDataSource _remoteDataSource;

  const CompanyRegionalSettingsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String businessTimezone,
  }) async {
    try {
      final model = await _remoteDataSource.update(
        companyId: companyId,
        baseCurrencyCode: baseCurrencyCode,
        baseCurrencyFractionDigits: baseCurrencyFractionDigits,
        businessTimezone: businessTimezone,
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
