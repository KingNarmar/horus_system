import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../company/domain/entities/current_company_context.dart';

CurrencyConfiguration? tripFinancialConfiguration(
  CurrentCompanyContext context,
) {
  return CurrencyConfiguration.tryCreate(
    currencyCode: context.company.baseCurrencyCode,
    fractionDigits: context.company.baseCurrencyFractionDigits,
  );
}
