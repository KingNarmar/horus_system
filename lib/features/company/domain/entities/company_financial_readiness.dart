import 'company_financial_configuration.dart';

enum CompanyFinancialReadinessStatus {
  configurationRequired,
  ready,
  invalidConfiguration,
}

final class CompanyFinancialReadiness {
  final CompanyFinancialReadinessStatus status;
  final CompanyFinancialConfiguration? configuration;

  const CompanyFinancialReadiness._({
    required this.status,
    required this.configuration,
  });

  const CompanyFinancialReadiness.configurationRequired()
    : this._(
        status: CompanyFinancialReadinessStatus.configurationRequired,
        configuration: null,
      );

  const CompanyFinancialReadiness.invalidConfiguration()
    : this._(
        status: CompanyFinancialReadinessStatus.invalidConfiguration,
        configuration: null,
      );

  const CompanyFinancialReadiness.ready(
    CompanyFinancialConfiguration configuration,
  ) : this._(
        status: CompanyFinancialReadinessStatus.ready,
        configuration: configuration,
      );

  bool get isReady => status == CompanyFinancialReadinessStatus.ready;
}
