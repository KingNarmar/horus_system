import '../../../../core/utils/result.dart';
import '../entities/company.dart';

abstract interface class CompanyRegionalSettingsRepository {
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
    required String businessTimezone,
  });
}
