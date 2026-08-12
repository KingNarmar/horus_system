import 'package:flutter/widgets.dart';

final class CustomerStatementsLocalizations {
  final Map<String, String> _values;

  const CustomerStatementsLocalizations._(this._values);

  factory CustomerStatementsLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const CustomerStatementsLocalizations._(_ar)
        : const CustomerStatementsLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get appShellLabel => _value('appShellLabel');
  String get appShellDescription => _value('appShellDescription');
  String get title => _value('title');
  String get loadingCustomers => _value('loadingCustomers');
  String get loadingStatement => _value('loadingStatement');
  String get retry => _value('retry');
  String get noCustomers => _value('noCustomers');
  String get selectCustomer => _value('selectCustomer');
  String get inactiveCustomer => _value('inactiveCustomer');
  String get fromDate => _value('fromDate');
  String get toDate => _value('toDate');
  String get chooseDate => _value('chooseDate');
  String get clearDate => _value('clearDate');
  String get applyFilters => _value('applyFilters');
  String get clearDates => _value('clearDates');
  String get selectCustomerPrompt => _value('selectCustomerPrompt');
  String get noMovements => _value('noMovements');
  String get openingBalance => _value('openingBalance');
  String get invoiced => _value('invoiced');
  String get paid => _value('paid');
  String get outstanding => _value('outstanding');
  String get date => _value('date');
  String get type => _value('type');
  String get reference => _value('reference');
  String get amount => _value('amount');
  String get balance => _value('balance');
  String get invoice => _value('invoice');
  String get payment => _value('payment');
  String get unavailableValue => _value('unavailableValue');
  String get permissionFailure => _value('permissionFailure');
  String get customerRequiredFailure => _value('customerRequiredFailure');
  String get dateRangeFailure => _value('dateRangeFailure');
  String get customerNotFoundFailure => _value('customerNotFoundFailure');
  String get sourceInvalidFailure => _value('sourceInvalidFailure');
  String get currencyMismatchFailure => _value('currencyMismatchFailure');
  String get movementInvalidFailure => _value('movementInvalidFailure');
  String get regionalSettingsFailure => _value('regionalSettingsFailure');
  String get companyNotFoundFailure => _value('companyNotFoundFailure');
  String get loadFailed => _value('loadFailed');

  String customerOption({required String name, required bool isActive}) {
    if (isActive) return name;
    return _value(
      'inactiveCustomerOption',
    ).replaceFirst('{name}', name);
  }

  static const Map<String, String> _en = {
    'appShellLabel': 'Customer Statements',
    'appShellDescription':
        'Review customer invoices, payments, and outstanding balances by date.',
    'title': 'Customer Statements',
    'loadingCustomers': 'Loading customers...',
    'loadingStatement': 'Loading customer statement...',
    'retry': 'Retry',
    'noCustomers': 'No customers are available for this company.',
    'selectCustomer': 'Select customer',
    'inactiveCustomer': 'Inactive customer',
    'fromDate': 'From date',
    'toDate': 'To date',
    'chooseDate': 'Choose date',
    'clearDate': 'Clear date',
    'applyFilters': 'Apply',
    'clearDates': 'Clear dates',
    'selectCustomerPrompt':
        'Select a customer and apply the filters to view the statement.',
    'noMovements': 'No invoices or payments match the selected period.',
    'openingBalance': 'Opening balance',
    'invoiced': 'Invoiced',
    'paid': 'Paid',
    'outstanding': 'Outstanding',
    'date': 'Date',
    'type': 'Type',
    'reference': 'Reference',
    'amount': 'Amount',
    'balance': 'Balance',
    'invoice': 'Invoice',
    'payment': 'Payment',
    'unavailableValue': 'Not available',
    'permissionFailure': 'This role cannot view customer statements.',
    'customerRequiredFailure': 'Select a customer.',
    'dateRangeFailure': 'The from date cannot be after the to date.',
    'customerNotFoundFailure':
        'The selected customer was not found in this company.',
    'sourceInvalidFailure':
        'The statement data is inconsistent. Reload and try again.',
    'currencyMismatchFailure':
        'The statement currency does not match the company currency.',
    'movementInvalidFailure':
        'The statement contains an invalid financial movement.',
    'regionalSettingsFailure':
        'Configure the company currency and business timezone first.',
    'companyNotFoundFailure': 'The current company could not be found.',
    'loadFailed': 'The customer statement could not be loaded.',
    'inactiveCustomerOption': '{name} — Inactive',
  };

  static const Map<String, String> _ar = {
    'appShellLabel': 'كشوف حساب العملاء',
    'appShellDescription':
        'مراجعة فواتير ومدفوعات العملاء والأرصدة المستحقة حسب التاريخ.',
    'title': 'كشوف حساب العملاء',
    'loadingCustomers': 'جاري تحميل العملاء...',
    'loadingStatement': 'جاري تحميل كشف حساب العميل...',
    'retry': 'إعادة المحاولة',
    'noCustomers': 'لا يوجد عملاء متاحون لهذه الشركة.',
    'selectCustomer': 'اختر العميل',
    'inactiveCustomer': 'عميل غير نشط',
    'fromDate': 'من تاريخ',
    'toDate': 'إلى تاريخ',
    'chooseDate': 'اختر التاريخ',
    'clearDate': 'مسح التاريخ',
    'applyFilters': 'تطبيق',
    'clearDates': 'مسح التواريخ',
    'selectCustomerPrompt':
        'اختر عميلًا ثم طبّق الفلاتر لعرض كشف الحساب.',
    'noMovements': 'لا توجد فواتير أو مدفوعات ضمن الفترة المحددة.',
    'openingBalance': 'الرصيد الافتتاحي',
    'invoiced': 'إجمالي الفواتير',
    'paid': 'المدفوع',
    'outstanding': 'الرصيد المستحق',
    'date': 'التاريخ',
    'type': 'النوع',
    'reference': 'المرجع',
    'amount': 'المبلغ',
    'balance': 'الرصيد',
    'invoice': 'فاتورة',
    'payment': 'دفعة',
    'unavailableValue': 'غير متاح',
    'permissionFailure': 'هذا الدور غير مسموح له بعرض كشوف حساب العملاء.',
    'customerRequiredFailure': 'اختر عميلًا.',
    'dateRangeFailure': 'لا يمكن أن يكون تاريخ البداية بعد تاريخ النهاية.',
    'customerNotFoundFailure':
        'تعذر العثور على العميل المحدد داخل هذه الشركة.',
    'sourceInvalidFailure':
        'بيانات كشف الحساب غير متسقة. أعد التحميل ثم حاول مرة أخرى.',
    'currencyMismatchFailure':
        'عملة كشف الحساب لا تطابق العملة المعتمدة للشركة.',
    'movementInvalidFailure':
        'يحتوي كشف الحساب على حركة مالية غير صالحة.',
    'regionalSettingsFailure':
        'اضبط عملة الشركة والمنطقة الزمنية للعمل أولًا.',
    'companyNotFoundFailure': 'تعذر العثور على الشركة الحالية.',
    'loadFailed': 'تعذر تحميل كشف حساب العميل.',
    'inactiveCustomerOption': '{name} — غير نشط',
  };
}

extension CustomerStatementsLocalizationsBuildContextX on BuildContext {
  CustomerStatementsLocalizations get customerStatementsL10n {
    return CustomerStatementsLocalizations.forLocale(
      Localizations.localeOf(this),
    );
  }
}
