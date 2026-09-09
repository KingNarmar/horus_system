import '../entities/company.dart';
import '../entities/company_financial_configuration.dart';
import '../entities/company_financial_readiness.dart';

abstract final class CompanyFinancialReadinessPolicy {
  static CompanyFinancialReadiness evaluate(Company company) {
    final rawCurrency = company.baseCurrencyCode?.trim();
    final fractionDigits = company.baseCurrencyFractionDigits;

    if ((rawCurrency == null || rawCurrency.isEmpty) && fractionDigits == null) {
      return const CompanyFinancialReadiness.configurationRequired();
    }

    final configuration = CompanyFinancialConfiguration.tryCreate(
      baseCurrencyCode: rawCurrency,
      fractionDigits: fractionDigits,
    );
    if (configuration == null) {
      return const CompanyFinancialReadiness.invalidConfiguration();
    }

    return CompanyFinancialReadiness.ready(configuration);
  }
}
