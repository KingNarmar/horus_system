import 'package:flutter/widgets.dart';

final class PaymentsLocalizations {
  final Map<String, String> _values;

  const PaymentsLocalizations._(this._values);

  factory PaymentsLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const PaymentsLocalizations._(_ar)
        : const PaymentsLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get appShellLabel => _value('appShellLabel');
  String get appShellDescription => _value('appShellDescription');
  String get title => _value('title');
  String get registerPayment => _value('registerPayment');
  String get registrationTitle => _value('registrationTitle');
  String get searchHint => _value('searchHint');
  String get loading => _value('loading');
  String get retry => _value('retry');
  String get noPayments => _value('noPayments');
  String get noMatchingPayments => _value('noMatchingPayments');
  String get noPayableInvoices => _value('noPayableInvoices');
  String get noActivePaymentMethods => _value('noActivePaymentMethods');
  String get invoice => _value('invoice');
  String get customer => _value('customer');
  String get paymentMethod => _value('paymentMethod');
  String get paymentDate => _value('paymentDate');
  String get amount => _value('amount');
  String get referenceNumber => _value('referenceNumber');
  String get notes => _value('notes');
  String get total => _value('total');
  String get paid => _value('paid');
  String get remaining => _value('remaining');
  String get createdAt => _value('createdAt');
  String get selectInvoice => _value('selectInvoice');
  String get selectPaymentMethod => _value('selectPaymentMethod');
  String get selectDate => _value('selectDate');
  String get invoiceRequired => _value('invoiceRequired');
  String get paymentMethodRequired => _value('paymentMethodRequired');
  String get amountRequired => _value('amountRequired');
  String get dateRequired => _value('dateRequired');
  String get cancel => _value('cancel');
  String get submit => _value('submit');
  String get submitting => _value('submitting');
  String get paymentRegistered => _value('paymentRegistered');
  String get loadFailed => _value('loadFailed');
  String get registrationLoadFailed => _value('registrationLoadFailed');
  String get registrationFailed => _value('registrationFailed');
  String get permissionViewFailure => _value('permissionViewFailure');
  String get permissionManageFailure => _value('permissionManageFailure');
  String get invoiceNotFoundFailure => _value('invoiceNotFoundFailure');
  String get methodNotFoundFailure => _value('methodNotFoundFailure');
  String get invoiceStatusFailure => _value('invoiceStatusFailure');
  String get amountInvalidFailure => _value('amountInvalidFailure');
  String get amountPositiveFailure => _value('amountPositiveFailure');
  String get currencyInvalidFailure => _value('currencyInvalidFailure');
  String get currencyMismatchFailure => _value('currencyMismatchFailure');
  String get dateBeforeInvoiceFailure => _value('dateBeforeInvoiceFailure');
  String get dateFutureFailure => _value('dateFutureFailure');
  String get inactiveMethodFailure => _value('inactiveMethodFailure');
  String get overpaymentFailure => _value('overpaymentFailure');
  String get balanceChangedFailure => _value('balanceChangedFailure');
  String get invoiceLinesFailure => _value('invoiceLinesFailure');
  String get tripStateFailure => _value('tripStateFailure');
  String get regionalSettingsFailure => _value('regionalSettingsFailure');
  String get unavailableValue => _value('unavailableValue');

  String invoiceOption({required String number, required String customer}) {
    return _value(
      'invoiceOption',
    ).replaceFirst('{number}', number).replaceFirst('{customer}', customer);
  }

  static const Map<String, String> _en = {
    'appShellLabel': 'Payments',
    'appShellDescription':
        'Register and review company-scoped customer payments against invoices.',
    'title': 'Payments',
    'registerPayment': 'Register payment',
    'registrationTitle': 'Register invoice payment',
    'searchHint':
        'Search invoice, customer, method, reference, amount, or notes',
    'loading': 'Loading payments...',
    'retry': 'Retry',
    'noPayments': 'No payments have been registered.',
    'noMatchingPayments': 'No payments match the current search.',
    'noPayableInvoices': 'No issued invoices have an outstanding balance.',
    'noActivePaymentMethods': 'No active payment methods are available.',
    'invoice': 'Invoice',
    'customer': 'Customer',
    'paymentMethod': 'Payment method',
    'paymentDate': 'Payment date',
    'amount': 'Amount',
    'referenceNumber': 'Reference number',
    'notes': 'Notes',
    'total': 'Invoice total',
    'paid': 'Paid',
    'remaining': 'Remaining',
    'createdAt': 'Registered at',
    'selectInvoice': 'Select an invoice',
    'selectPaymentMethod': 'Select a payment method',
    'selectDate': 'Select payment date',
    'invoiceRequired': 'Select an invoice.',
    'paymentMethodRequired': 'Select a payment method.',
    'amountRequired': 'Enter a valid payment amount.',
    'dateRequired': 'Select a payment date.',
    'cancel': 'Cancel',
    'submit': 'Register payment',
    'submitting': 'Registering...',
    'paymentRegistered': 'Payment registered successfully.',
    'loadFailed': 'Payments could not be loaded.',
    'registrationLoadFailed':
        'Payment registration options could not be loaded.',
    'registrationFailed': 'The payment could not be registered.',
    'permissionViewFailure': 'This role cannot view payments.',
    'permissionManageFailure': 'This role cannot register payments.',
    'invoiceNotFoundFailure':
        'The selected invoice was not found in this company.',
    'methodNotFoundFailure': 'The selected payment method was not found.',
    'invoiceStatusFailure': 'The selected invoice is no longer payable.',
    'amountInvalidFailure':
        'Enter an amount using the company currency precision.',
    'amountPositiveFailure': 'The payment amount must be greater than zero.',
    'currencyInvalidFailure': 'The payment currency is invalid.',
    'currencyMismatchFailure':
        'The payment currency does not match the invoice.',
    'dateBeforeInvoiceFailure':
        'The payment date cannot be before the invoice date.',
    'dateFutureFailure':
        'The payment date cannot be after the company business date.',
    'inactiveMethodFailure': 'The selected payment method is inactive.',
    'overpaymentFailure':
        'The payment exceeds the invoice outstanding balance.',
    'balanceChangedFailure':
        'The invoice balance changed. Reload the payment form and try again.',
    'invoiceLinesFailure': 'The invoice has no payable trip lines.',
    'tripStateFailure':
        'A linked trip changed state. Reload the invoice and try again.',
    'regionalSettingsFailure':
        'Configure the company currency and business timezone first.',
    'unavailableValue': 'Not available',
    'invoiceOption': '{number} — {customer}',
  };

  static const Map<String, String> _ar = {
    'appShellLabel': 'المدفوعات',
    'appShellDescription':
        'تسجيل ومراجعة مدفوعات العملاء الخاصة بالشركة مقابل الفواتير.',
    'title': 'المدفوعات',
    'registerPayment': 'تسجيل دفعة',
    'registrationTitle': 'تسجيل دفعة على فاتورة',
    'searchHint':
        'ابحث بالفاتورة أو العميل أو طريقة الدفع أو المرجع أو المبلغ أو الملاحظات',
    'loading': 'جاري تحميل المدفوعات...',
    'retry': 'إعادة المحاولة',
    'noPayments': 'لا توجد مدفوعات مسجلة.',
    'noMatchingPayments': 'لا توجد مدفوعات مطابقة للبحث الحالي.',
    'noPayableInvoices': 'لا توجد فواتير صادرة لها رصيد مستحق.',
    'noActivePaymentMethods': 'لا توجد طرق دفع نشطة متاحة.',
    'invoice': 'الفاتورة',
    'customer': 'العميل',
    'paymentMethod': 'طريقة الدفع',
    'paymentDate': 'تاريخ الدفع',
    'amount': 'المبلغ',
    'referenceNumber': 'الرقم المرجعي',
    'notes': 'ملاحظات',
    'total': 'إجمالي الفاتورة',
    'paid': 'المدفوع',
    'remaining': 'المتبقي',
    'createdAt': 'وقت التسجيل',
    'selectInvoice': 'اختر فاتورة',
    'selectPaymentMethod': 'اختر طريقة دفع',
    'selectDate': 'اختر تاريخ الدفع',
    'invoiceRequired': 'اختر فاتورة.',
    'paymentMethodRequired': 'اختر طريقة دفع.',
    'amountRequired': 'أدخل مبلغ دفع صالحًا.',
    'dateRequired': 'اختر تاريخ الدفع.',
    'cancel': 'إلغاء',
    'submit': 'تسجيل الدفعة',
    'submitting': 'جاري التسجيل...',
    'paymentRegistered': 'تم تسجيل الدفعة بنجاح.',
    'loadFailed': 'تعذر تحميل المدفوعات.',
    'registrationLoadFailed': 'تعذر تحميل خيارات تسجيل الدفعة.',
    'registrationFailed': 'تعذر تسجيل الدفعة.',
    'permissionViewFailure': 'هذا الدور غير مسموح له بعرض المدفوعات.',
    'permissionManageFailure': 'هذا الدور غير مسموح له بتسجيل المدفوعات.',
    'invoiceNotFoundFailure':
        'تعذر العثور على الفاتورة المحددة داخل هذه الشركة.',
    'methodNotFoundFailure': 'تعذر العثور على طريقة الدفع المحددة.',
    'invoiceStatusFailure': 'الفاتورة المحددة لم تعد قابلة لاستقبال دفعات.',
    'amountInvalidFailure': 'أدخل المبلغ بدقة العملة المعتمدة للشركة.',
    'amountPositiveFailure': 'يجب أن يكون مبلغ الدفعة أكبر من صفر.',
    'currencyInvalidFailure': 'عملة الدفعة غير صالحة.',
    'currencyMismatchFailure': 'عملة الدفعة لا تطابق عملة الفاتورة.',
    'dateBeforeInvoiceFailure': 'لا يمكن أن يسبق تاريخ الدفع تاريخ الفاتورة.',
    'dateFutureFailure': 'لا يمكن أن يتجاوز تاريخ الدفع تاريخ عمل الشركة.',
    'inactiveMethodFailure': 'طريقة الدفع المحددة غير نشطة.',
    'overpaymentFailure': 'مبلغ الدفعة يتجاوز الرصيد المتبقي على الفاتورة.',
    'balanceChangedFailure':
        'تغير رصيد الفاتورة. أعد تحميل نموذج الدفع ثم حاول مرة أخرى.',
    'invoiceLinesFailure': 'لا تحتوي الفاتورة على بنود رحلات قابلة للسداد.',
    'tripStateFailure':
        'تغيرت حالة إحدى الرحلات المرتبطة. أعد تحميل الفاتورة ثم حاول مرة أخرى.',
    'regionalSettingsFailure': 'اضبط عملة الشركة والمنطقة الزمنية للعمل أولًا.',
    'unavailableValue': 'غير متاح',
    'invoiceOption': '{number} — {customer}',
  };
}

extension PaymentsLocalizationsBuildContextX on BuildContext {
  PaymentsLocalizations get paymentsL10n {
    return PaymentsLocalizations.forLocale(Localizations.localeOf(this));
  }
}
