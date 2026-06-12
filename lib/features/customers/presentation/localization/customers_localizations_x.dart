import '../../../../l10n/app_localizations.dart';

extension CustomersLocalizationsX on AppLocalizations {
  bool get _isArabic => localeName.startsWith('ar');

  String get reactivateCustomerButton {
    return _isArabic ? 'إعادة تفعيل' : 'Reactivate';
  }

  String get searchCustomersHint {
    return _isArabic
        ? 'ابحث في العملاء بالاسم أو المسؤول أو الهاتف أو البريد أو المدينة أو الدولة أو الرقم الضريبي'
        : 'Search customers by name, contact, phone, email, city, country, or TRN';
  }

  String get customersStatusAllFilter {
    return _isArabic ? 'الكل' : 'All';
  }

  String get customersStatusActiveFilter {
    return _isArabic ? 'النشط' : 'Active';
  }

  String get customersStatusInactiveFilter {
    return _isArabic ? 'غير النشط' : 'Inactive';
  }

  String get noCustomersMatchFilters {
    return _isArabic
        ? 'لا يوجد عملاء مطابقون للبحث أو فلتر الحالة الحالي.'
        : 'No customers match the current search or status filter.';
  }
}
