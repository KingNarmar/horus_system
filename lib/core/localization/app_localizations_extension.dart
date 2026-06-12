import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension CustomersLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get reactivateCustomerButton => _isArabic ? 'إعادة تفعيل' : 'Reactivate';

  String get searchCustomersHint => _isArabic
      ? 'ابحث في العملاء بالاسم أو المسؤول أو الهاتف أو البريد أو المدينة أو الدولة أو الرقم الضريبي'
      : 'Search customers by name, contact, phone, email, city, country, or TRN';

  String get customersStatusAllFilter => _isArabic ? 'الكل' : 'All';

  String get customersStatusActiveFilter => _isArabic ? 'النشط' : 'Active';

  String get customersStatusInactiveFilter =>
      _isArabic ? 'غير النشط' : 'Inactive';

  String get noCustomersMatchFilters => _isArabic
      ? 'لا يوجد عملاء مطابقون للبحث أو فلتر الحالة الحالي.'
      : 'No customers match the current search or status filter.';
}
