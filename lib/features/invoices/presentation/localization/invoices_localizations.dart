import 'package:flutter/widgets.dart';

final class InvoicesLocalizations {
  final Map<String, String> _values;

  const InvoicesLocalizations._(this._values);

  factory InvoicesLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const InvoicesLocalizations._(_ar)
        : const InvoicesLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get appShellLabel => _value('appShellLabel');
  String get appShellDescription => _value('appShellDescription');
  String get title => _value('title');
  String get newDraft => _value('newDraft');
  String get createDraftTitle => _value('createDraftTitle');
  String get trip => _value('trip');
  String get selectTrip => _value('selectTrip');
  String get tripRequired => _value('tripRequired');
  String get notes => _value('notes');
  String get saveDraft => _value('saveDraft');
  String get savingDraft => _value('savingDraft');
  String get searchHint => _value('searchHint');
  String get allStatuses => _value('allStatuses');
  String get statusDraft => _value('statusDraft');
  String get statusIssued => _value('statusIssued');
  String get statusCancelled => _value('statusCancelled');
  String get number => _value('number');
  String get draftNumber => _value('draftNumber');
  String get customer => _value('customer');
  String get issueDate => _value('issueDate');
  String get dueDate => _value('dueDate');
  String get total => _value('total');
  String get subtotal => _value('subtotal');
  String get discount => _value('discount');
  String get taxableAmount => _value('taxableAmount');
  String get tax => _value('tax');
  String get status => _value('status');
  String get actions => _value('actions');
  String get details => _value('details');
  String get invoiceDetails => _value('invoiceDetails');
  String get invoiceLines => _value('invoiceLines');
  String get activity => _value('activity');
  String get noActivity => _value('noActivity');
  String get loadingActivity => _value('loadingActivity');
  String get noInvoices => _value('noInvoices');
  String get noMatchingInvoices => _value('noMatchingInvoices');
  String get noBillableTrips => _value('noBillableTrips');
  String get loadingBillableTrips => _value('loadingBillableTrips');
  String get issue => _value('issue');
  String get issuing => _value('issuing');
  String get issueTitle => _value('issueTitle');
  String get selectIssueDate => _value('selectIssueDate');
  String get selectDueDate => _value('selectDueDate');
  String get dateRequired => _value('dateRequired');
  String get cancelInvoice => _value('cancelInvoice');
  String get cancelling => _value('cancelling');
  String get cancelTitle => _value('cancelTitle');
  String get cancellationReason => _value('cancellationReason');
  String get cancellationReasonRequired => _value('cancellationReasonRequired');
  String get close => _value('close');
  String get draftCreated => _value('draftCreated');
  String get draftUpdated => _value('draftUpdated');
  String get invoiceIssued => _value('invoiceIssued');
  String get invoiceCancelled => _value('invoiceCancelled');
  String get loadFailed => _value('loadFailed');
  String get detailsFailed => _value('detailsFailed');
  String get draftFailed => _value('draftFailed');
  String get permissionViewFailure => _value('permissionViewFailure');
  String get permissionManageFailure => _value('permissionManageFailure');
  String get customerRequiredFailure => _value('customerRequiredFailure');
  String get tripsRequiredFailure => _value('tripsRequiredFailure');
  String get singleTripRequiredFailure => _value('singleTripRequiredFailure');
  String get tripNotBillableFailure => _value('tripNotBillableFailure');
  String get tripAlreadyInvoicedFailure => _value('tripAlreadyInvoicedFailure');
  String get customerInactiveFailure => _value('customerInactiveFailure');
  String get regionalSettingsFailure => _value('regionalSettingsFailure');
  String get settingsFailure => _value('settingsFailure');
  String get invoiceNotFoundFailure => _value('invoiceNotFoundFailure');
  String get issueDateFutureFailure => _value('issueDateFutureFailure');
  String get dueDateBeforeIssueFailure => _value('dueDateBeforeIssueFailure');
  String get cancellationReasonFailure => _value('cancellationReasonFailure');
  String get invalidStatusFailure => _value('invalidStatusFailure');
  String get invoiceChangedFailure => _value('invoiceChangedFailure');
  String get unavailableValue => _value('unavailableValue');
  String get auditCreated => _value('auditCreated');
  String get auditUpdated => _value('auditUpdated');
  String get auditIssued => _value('auditIssued');
  String get auditCancelled => _value('auditCancelled');

  String tripOption(String reference, String amount) => _value('tripOption')
      .replaceFirst('{reference}', reference)
      .replaceFirst('{amount}', amount);

  String lineReference(String reference) =>
      _value('lineReference').replaceFirst('{reference}', reference);

  static const Map<String, String> _en = {
    'appShellLabel': 'Invoices',
    'appShellDescription':
        'Create, issue, cancel, and review company-scoped transport invoices.',
    'title': 'Invoices',
    'newDraft': 'New invoice',
    'createDraftTitle': 'Create invoice draft',
    'trip': 'Billable trip',
    'selectTrip': 'Select a trip',
    'tripRequired': 'Select one billable trip.',
    'notes': 'Notes',
    'saveDraft': 'Save draft',
    'savingDraft': 'Saving...',
    'searchHint': 'Search number, customer, status, amount, or notes',
    'allStatuses': 'All statuses',
    'statusDraft': 'Draft',
    'statusIssued': 'Issued',
    'statusCancelled': 'Cancelled',
    'number': 'Invoice number',
    'draftNumber': 'Draft',
    'customer': 'Customer',
    'issueDate': 'Issue date',
    'dueDate': 'Due date',
    'total': 'Total',
    'subtotal': 'Subtotal',
    'discount': 'Discount',
    'taxableAmount': 'Taxable amount',
    'tax': 'Tax',
    'status': 'Status',
    'actions': 'Actions',
    'details': 'Details',
    'invoiceDetails': 'Invoice details',
    'invoiceLines': 'Invoice lines',
    'activity': 'Activity timeline',
    'noActivity': 'No invoice activity found.',
    'loadingActivity': 'Loading activity...',
    'noInvoices': 'No invoices found.',
    'noMatchingInvoices': 'No invoices match the current filters.',
    'noBillableTrips': 'No billable trips are available.',
    'loadingBillableTrips': 'Loading billable trips...',
    'issue': 'Issue invoice',
    'issuing': 'Issuing...',
    'issueTitle': 'Issue invoice',
    'selectIssueDate': 'Select issue date',
    'selectDueDate': 'Select due date',
    'dateRequired': 'Select a date.',
    'cancelInvoice': 'Cancel invoice',
    'cancelling': 'Cancelling...',
    'cancelTitle': 'Cancel invoice',
    'cancellationReason': 'Cancellation reason',
    'cancellationReasonRequired': 'Enter a cancellation reason.',
    'close': 'Close',
    'draftCreated': 'Invoice draft created.',
    'draftUpdated': 'Invoice draft updated.',
    'invoiceIssued': 'Invoice issued.',
    'invoiceCancelled': 'Invoice cancelled.',
    'loadFailed': 'Invoices could not be loaded.',
    'detailsFailed': 'Invoice details could not be loaded.',
    'draftFailed': 'The invoice draft could not be saved.',
    'permissionViewFailure': 'This role cannot view invoices.',
    'permissionManageFailure': 'This role cannot manage invoice drafts.',
    'customerRequiredFailure': 'An invoice customer is required.',
    'tripsRequiredFailure': 'At least one billable trip is required.',
    'singleTripRequiredFailure': 'Select exactly one trip for this invoice.',
    'tripNotBillableFailure': 'The selected trip is no longer billable.',
    'tripAlreadyInvoicedFailure': 'The selected trip is already invoiced.',
    'customerInactiveFailure': 'The selected customer is inactive.',
    'regionalSettingsFailure':
        'Configure the company currency and business timezone first.',
    'settingsFailure': 'Configure invoice settings first.',
    'invoiceNotFoundFailure': 'The invoice was not found in this company.',
    'issueDateFutureFailure':
        'The issue date cannot be after the company business date.',
    'dueDateBeforeIssueFailure':
        'The due date cannot be before the issue date.',
    'cancellationReasonFailure': 'A cancellation reason is required.',
    'invalidStatusFailure':
        'This action is not allowed for the current invoice status.',
    'invoiceChangedFailure':
        'The invoice or its trips changed. Reload the invoice and try again.',
    'unavailableValue': 'Not available',
    'auditCreated': 'Invoice draft created',
    'auditUpdated': 'Invoice draft updated',
    'auditIssued': 'Invoice issued',
    'auditCancelled': 'Invoice cancelled',
    'tripOption': '{reference} • {amount}',
    'lineReference': 'Trip {reference}',
  };

  static const Map<String, String> _ar = {
    'appShellLabel': 'الفواتير',
    'appShellDescription':
        'إنشاء وإصدار وإلغاء ومراجعة فواتير النقل الخاصة بالشركة.',
    'title': 'الفواتير',
    'newDraft': 'فاتورة جديدة',
    'createDraftTitle': 'إنشاء مسودة فاتورة',
    'trip': 'الرحلة القابلة للفوترة',
    'selectTrip': 'اختر رحلة',
    'tripRequired': 'اختر رحلة واحدة قابلة للفوترة.',
    'notes': 'ملاحظات',
    'saveDraft': 'حفظ المسودة',
    'savingDraft': 'جاري الحفظ...',
    'searchHint': 'ابحث برقم الفاتورة أو العميل أو الحالة أو المبلغ أو الملاحظات',
    'allStatuses': 'كل الحالات',
    'statusDraft': 'مسودة',
    'statusIssued': 'صادرة',
    'statusCancelled': 'ملغاة',
    'number': 'رقم الفاتورة',
    'draftNumber': 'مسودة',
    'customer': 'العميل',
    'issueDate': 'تاريخ الإصدار',
    'dueDate': 'تاريخ الاستحقاق',
    'total': 'الإجمالي',
    'subtotal': 'الإجمالي قبل الخصم',
    'discount': 'الخصم',
    'taxableAmount': 'المبلغ الخاضع للضريبة',
    'tax': 'الضريبة',
    'status': 'الحالة',
    'actions': 'الإجراءات',
    'details': 'التفاصيل',
    'invoiceDetails': 'تفاصيل الفاتورة',
    'invoiceLines': 'بنود الفاتورة',
    'activity': 'سجل النشاط',
    'noActivity': 'لا يوجد نشاط مسجل لهذه الفاتورة.',
    'loadingActivity': 'جاري تحميل سجل النشاط...',
    'noInvoices': 'لا توجد فواتير.',
    'noMatchingInvoices': 'لا توجد فواتير مطابقة للفلاتر الحالية.',
    'noBillableTrips': 'لا توجد رحلات متاحة للفوترة.',
    'loadingBillableTrips': 'جاري تحميل الرحلات القابلة للفوترة...',
    'issue': 'إصدار الفاتورة',
    'issuing': 'جاري الإصدار...',
    'issueTitle': 'إصدار الفاتورة',
    'selectIssueDate': 'اختر تاريخ الإصدار',
    'selectDueDate': 'اختر تاريخ الاستحقاق',
    'dateRequired': 'اختر تاريخًا.',
    'cancelInvoice': 'إلغاء الفاتورة',
    'cancelling': 'جاري الإلغاء...',
    'cancelTitle': 'إلغاء الفاتورة',
    'cancellationReason': 'سبب الإلغاء',
    'cancellationReasonRequired': 'أدخل سبب الإلغاء.',
    'close': 'إغلاق',
    'draftCreated': 'تم إنشاء مسودة الفاتورة.',
    'draftUpdated': 'تم تحديث مسودة الفاتورة.',
    'invoiceIssued': 'تم إصدار الفاتورة.',
    'invoiceCancelled': 'تم إلغاء الفاتورة.',
    'loadFailed': 'تعذر تحميل الفواتير.',
    'detailsFailed': 'تعذر تحميل تفاصيل الفاتورة.',
    'draftFailed': 'تعذر حفظ مسودة الفاتورة.',
    'permissionViewFailure': 'هذا الدور غير مسموح له بعرض الفواتير.',
    'permissionManageFailure': 'هذا الدور غير مسموح له بإدارة مسودات الفواتير.',
    'customerRequiredFailure': 'يجب تحديد عميل الفاتورة.',
    'tripsRequiredFailure': 'يجب تحديد رحلة واحدة قابلة للفوترة على الأقل.',
    'singleTripRequiredFailure': 'اختر رحلة واحدة فقط لهذه الفاتورة.',
    'tripNotBillableFailure': 'الرحلة المحددة لم تعد قابلة للفوترة.',
    'tripAlreadyInvoicedFailure': 'تمت فوترة الرحلة المحددة بالفعل.',
    'customerInactiveFailure': 'العميل المحدد غير نشط.',
    'regionalSettingsFailure':
        'اضبط عملة الشركة والمنطقة الزمنية للعمل أولًا.',
    'settingsFailure': 'اضبط إعدادات الفواتير أولًا.',
    'invoiceNotFoundFailure': 'تعذر العثور على الفاتورة داخل هذه الشركة.',
    'issueDateFutureFailure':
        'لا يمكن أن يكون تاريخ الإصدار بعد تاريخ عمل الشركة.',
    'dueDateBeforeIssueFailure':
        'لا يمكن أن يكون تاريخ الاستحقاق قبل تاريخ الإصدار.',
    'cancellationReasonFailure': 'سبب إلغاء الفاتورة مطلوب.',
    'invalidStatusFailure':
        'هذا الإجراء غير مسموح للحالة الحالية للفاتورة.',
    'invoiceChangedFailure':
        'تغيرت الفاتورة أو رحلاتها. أعد تحميل الفاتورة وحاول مرة أخرى.',
    'unavailableValue': 'غير متاح',
    'auditCreated': 'تم إنشاء مسودة الفاتورة',
    'auditUpdated': 'تم تحديث مسودة الفاتورة',
    'auditIssued': 'تم إصدار الفاتورة',
    'auditCancelled': 'تم إلغاء الفاتورة',
    'tripOption': '{reference} • {amount}',
    'lineReference': 'الرحلة {reference}',
  };
}

extension InvoicesLocalizationsContextX on BuildContext {
  InvoicesLocalizations get invoicesL10n =>
      InvoicesLocalizations.forLocale(Localizations.localeOf(this));
}
