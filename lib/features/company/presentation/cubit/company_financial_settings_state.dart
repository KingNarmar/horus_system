import '../../../../core/errors/failure.dart';
import '../../domain/entities/company.dart';

sealed class CompanyFinancialSettingsState {
  const CompanyFinancialSettingsState();
}

final class CompanyFinancialSettingsInitial
    extends CompanyFinancialSettingsState {
  const CompanyFinancialSettingsInitial();
}

final class CompanyFinancialSettingsSaving
    extends CompanyFinancialSettingsState {
  const CompanyFinancialSettingsSaving();
}

final class CompanyFinancialSettingsSaved extends CompanyFinancialSettingsState {
  final Company company;

  const CompanyFinancialSettingsSaved(this.company);
}

final class CompanyFinancialSettingsFailure
    extends CompanyFinancialSettingsState {
  final Failure failure;

  const CompanyFinancialSettingsFailure(this.failure);
}
