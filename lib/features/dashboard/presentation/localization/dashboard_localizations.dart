import 'package:flutter/widgets.dart';

final class DashboardLocalizations {
  final Map<String, String> _values;

  const DashboardLocalizations._(this._values);

  factory DashboardLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const DashboardLocalizations._(_ar)
        : const DashboardLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get title => _value('title');
  String get loading => _value('loading');
  String get retry => _value('retry');
  String get todayTrips => _value('todayTrips');
  String get runningTrips => _value('runningTrips');
  String get deliveredTrips => _value('deliveredTrips');
  String get availableVehicles => _value('availableVehicles');
  String get vehiclesOnTrip => _value('vehiclesOnTrip');
  String get totalRevenue => _value('totalRevenue');
  String get totalExpenses => _value('totalExpenses');
  String get netProfit => _value('netProfit');
  String get unpaidInvoices => _value('unpaidInvoices');
  String get permissionFailure => _value('permissionFailure');
  String get regionalSettingsFailure => _value('regionalSettingsFailure');
  String get companyNotFoundFailure => _value('companyNotFoundFailure');
  String get sourceInvalidFailure => _value('sourceInvalidFailure');
  String get currencyMismatchFailure => _value('currencyMismatchFailure');
  String get financialDataInvalidFailure =>
      _value('financialDataInvalidFailure');
  String get loadFailed => _value('loadFailed');

  String businessDate(String value) {
    return _value('businessDate').replaceFirst('{date}', value);
  }

  static const Map<String, String> _en = {
    'title': 'Dashboard',
    'loading': 'Loading dashboard...',
    'retry': 'Retry',
    'businessDate': 'Business date: {date}',
    'todayTrips': 'Today trips',
    'runningTrips': 'Running trips',
    'deliveredTrips': 'Delivered trips',
    'availableVehicles': 'Available vehicles',
    'vehiclesOnTrip': 'Vehicles on trip',
    'totalRevenue': 'Total revenue',
    'totalExpenses': 'Total expenses',
    'netProfit': 'Net profit',
    'unpaidInvoices': 'Unpaid invoices',
    'permissionFailure': 'This role cannot view the management dashboard.',
    'regionalSettingsFailure':
        'Configure the company currency and business timezone first.',
    'companyNotFoundFailure': 'The current company could not be found.',
    'sourceInvalidFailure':
        'The dashboard data is inconsistent. Reload and try again.',
    'currencyMismatchFailure':
        'Dashboard financial data does not match the company currency.',
    'financialDataInvalidFailure':
        'Dashboard financial data contains an invalid balance or amount.',
    'loadFailed': 'The dashboard could not be loaded.',
  };

  static const Map<String, String> _ar = {
    'title': 'لوحة التحكم',
    'loading': 'جاري تحميل لوحة التحكم...',
    'retry': 'إعادة المحاولة',
    'businessDate': 'تاريخ العمل: {date}',
    'todayTrips': 'رحلات اليوم',
    'runningTrips': 'الرحلات الجارية',
    'deliveredTrips': 'الرحلات المسلّمة',
    'availableVehicles': 'المركبات المتاحة',
    'vehiclesOnTrip': 'المركبات في رحلات',
    'totalRevenue': 'إجمالي الإيرادات',
    'totalExpenses': 'إجمالي المصروفات',
    'netProfit': 'صافي الربح',
    'unpaidInvoices': 'الفواتير غير المسددة',
    'permissionFailure': 'هذا الدور غير مسموح له بعرض لوحة الإدارة.',
    'regionalSettingsFailure': 'اضبط عملة الشركة والمنطقة الزمنية للعمل أولًا.',
    'companyNotFoundFailure': 'تعذر العثور على الشركة الحالية.',
    'sourceInvalidFailure':
        'بيانات لوحة التحكم غير متسقة. أعد التحميل ثم حاول مرة أخرى.',
    'currencyMismatchFailure':
        'البيانات المالية للوحة التحكم لا تطابق عملة الشركة.',
    'financialDataInvalidFailure':
        'تحتوي البيانات المالية للوحة التحكم على رصيد أو مبلغ غير صالح.',
    'loadFailed': 'تعذر تحميل لوحة التحكم.',
  };
}

extension DashboardLocalizationsBuildContextX on BuildContext {
  DashboardLocalizations get dashboardL10n {
    return DashboardLocalizations.forLocale(Localizations.localeOf(this));
  }
}
