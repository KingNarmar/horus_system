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
  String get status => _value('status');
  String get actions => _value('actions');
  String get details => _value('details');
  String get noInvoices => _value('noInvoices');
  String get noMatchingInvoices => _value('noMatchingInvoices');
  String get noBillableTrips => _value('noBillableTrips');
  String get loadingBillableTrips => _value('loadingBillableTrips');
  String get draftCreated => _value('draftCreated');
  String get draftUpdated => _value('draftUpdated');
  String get loadFailed => _value('loadFailed');
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
  String get unavailableValue => _value('unavailableValue');

  String tripOption(String reference, String amount) => _value('tripOption')
      .replaceFirst('{reference}', reference)
      .replaceFirst('{amount}', amount);

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
    'status': 'Status',
    'actions': 'Actions',
    'details': 'Details',
    'noInvoices': 'No invoices found.',
    'noMatchingInvoices': 'No invoices match the current filters.',
    'noBillableTrips': 'No billable trips are available.',
    'loadingBillableTrips': 'Loading billable trips...',
    'draftCreated': 'Invoice draft created.',
    'draftUpdated': 'Invoice draft updated.',
    'loadFailed': 'Invoices could not be loaded.',
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
    'unavailableValue': 'Not available',
    'tripOption': '{reference} • {amount}',
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
    'status': 'الحالة',
    'actions': 'الإجراءات',
    'details': 'التفاصيل',
    'noInvoices': 'لا توجد فواتير.',
    'noMatchingInvoices': 'لا توجد فواتير مطابقة للفلاتر الحالية.',
    'noBillableTrips': 'لا توجد رحلات متاحة للفوترة.',
    'loadingBillableTrips': 'جاري تحميل الرحلات القابلة للفوترة...',
    'draftCreated': 'تم إنشاء مسودة الفاتورة.',
    'draftUpdated': 'تم تحديث مسودة الفاتورة.',
    'loadFailed': 'تعذر تحميل الفواتير.',
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
    'unavailableValue': 'غير متاح',
    'tripOption': '{reference} • {amount}',
  };
}

extension InvoicesLocalizationsContextX on BuildContext {
  InvoicesLocalizations get invoicesL10n =>
      InvoicesLocalizations.forLocale(Localizations.localeOf(this));
}
