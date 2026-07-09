import '../../../../l10n/app_localizations.dart';

extension CompanyExpenseCategoryLocalizationsX on AppLocalizations {
  String companyExpenseCategoryName({
    required String? code,
    required String fallbackName,
  }) {
    return switch (code) {
      'vehicle_maintenance' => companyExpenseCategoryVehicleMaintenance,
      'spare_parts' => companyExpenseCategorySpareParts,
      'tires' => companyExpenseCategoryTires,
      'oils_and_fluids' => companyExpenseCategoryOilsAndFluids,
      'licenses_and_renewals' => companyExpenseCategoryLicensesAndRenewals,
      'office_expenses' => companyExpenseCategoryOfficeExpenses,
      'rent' => companyExpenseCategoryRent,
      'salaries' => companyExpenseCategorySalaries,
      'admin_costs' => companyExpenseCategoryAdminCosts,
      'fines' => companyExpenseCategoryFines,
      'other' => companyExpenseCategoryOther,
      _ => fallbackName,
    };
  }
}
