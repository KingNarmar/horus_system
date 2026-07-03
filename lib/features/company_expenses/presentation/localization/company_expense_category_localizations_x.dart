import '../../../../l10n/app_localizations.dart';

extension CompanyExpenseCategoryLocalizationsX on AppLocalizations {
  bool get _isArabicCompanyExpenseCategory => localeName.startsWith('ar');

  String companyExpenseCategoryName({
    required String? code,
    required String fallbackName,
  }) {
    return switch (code) {
      'vehicle_maintenance' => _isArabicCompanyExpenseCategory
          ? 'صيانة المركبات'
          : 'Vehicle maintenance',
      'spare_parts' => _isArabicCompanyExpenseCategory
          ? 'قطع الغيار'
          : 'Spare parts',
      'tires' => _isArabicCompanyExpenseCategory ? 'الإطارات' : 'Tires',
      'oils_and_fluids' => _isArabicCompanyExpenseCategory
          ? 'الزيوت والسوائل'
          : 'Oils and fluids',
      'licenses_and_renewals' => _isArabicCompanyExpenseCategory
          ? 'التراخيص والتجديدات'
          : 'Licenses and renewals',
      'office_expenses' => _isArabicCompanyExpenseCategory
          ? 'مصروفات المكتب'
          : 'Office expenses',
      'rent' => _isArabicCompanyExpenseCategory ? 'الإيجار' : 'Rent',
      'salaries' => _isArabicCompanyExpenseCategory ? 'الرواتب' : 'Salaries',
      'admin_costs' => _isArabicCompanyExpenseCategory
          ? 'المصروفات الإدارية'
          : 'Admin costs',
      'fines' => _isArabicCompanyExpenseCategory ? 'الغرامات' : 'Fines',
      'other' => _isArabicCompanyExpenseCategory ? 'أخرى' : 'Other',
      _ => fallbackName,
    };
  }
}
