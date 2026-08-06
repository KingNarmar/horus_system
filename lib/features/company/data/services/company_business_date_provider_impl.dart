import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/domain/services/company_business_date_provider.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../datasources/company_business_date_remote_data_source.dart';
import '../mappers/company_regional_settings_failure_mapper.dart';

final class CompanyBusinessDateProviderImpl
    implements CompanyBusinessDateProvider {
  final CompanyBusinessDateRemoteDataSource _remoteDataSource;

  const CompanyBusinessDateProviderImpl(this._remoteDataSource);

  @override
  Future<Result<DateTime>> getBusinessDate({required String companyId}) async {
    try {
      final model = await _remoteDataSource.getBusinessDate(
        companyId: companyId,
      );
      return Success(model.value);
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        CompanyRegionalSettingsFailureMapper.fromPostgrest(error),
      );
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
