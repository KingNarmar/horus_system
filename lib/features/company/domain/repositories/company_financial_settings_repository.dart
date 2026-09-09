import '../../../../core/utils/result.dart';
import '../entities/company.dart';

abstract class CompanyFinancialSettingsRepository {
  Future<Result<Company>> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  });
}
