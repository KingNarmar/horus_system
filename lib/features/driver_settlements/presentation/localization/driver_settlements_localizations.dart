import 'package:flutter/widgets.dart';

// Generated from driver_settlements_en.arb and driver_settlements_ar.arb.
class DriverSettlementsLocalizations {
  final Map<String, String> _values;

  const DriverSettlementsLocalizations._(this._values);

  factory DriverSettlementsLocalizations.forLocale(Locale locale) {
    return locale.languageCode == 'ar'
        ? const DriverSettlementsLocalizations._(_ar)
        : const DriverSettlementsLocalizations._(_en);
  }

  String _value(String key) => _values[key]!;

  String get appShellLabel => _value('appShellLabel');
  String get appShellDescription => _value('appShellDescription');
  String get title => _value('title');
  String get addDraft => _value('addDraft');
  String get searchHint => _value('searchHint');
  String get allDrivers => _value('allDrivers');
  String get allStatuses => _value('allStatuses');
  String get showVoided => _value('showVoided');
  String get noSettlements => _value('noSettlements');
  String get noMatchingSettlements => _value('noMatchingSettlements');
  String get details => _value('details');
  String get newDraftTitle => _value('newDraftTitle');
  String get driverLabel => _value('driverLabel');
  String get driverRequired => _value('driverRequired');
  String get periodStart => _value('periodStart');
  String get periodEnd => _value('periodEnd');
  String get periodInvalid => _value('periodInvalid');
  String get grossSalary => _value('grossSalary');
  String get salaryDeductions => _value('salaryDeductions');
  String get balanceDeduction => _value('balanceDeduction');
  String get settlementDeductions => _value('settlementDeductions');
  String get notes => _value('notes');
  String get nonNegativeAmount => _value('nonNegativeAmount');
  String get calculatePreview => _value('calculatePreview');
  String get calculatingPreview => _value('calculatingPreview');
  String get saveDraft => _value('saveDraft');
  String get savingDraft => _value('savingDraft');
  String get previewTitle => _value('previewTitle');
  String get calculationBreakdown => _value('calculationBreakdown');
  String get sourceItems => _value('sourceItems');
  String get noSourceItems => _value('noSourceItems');
  String get statusDraft => _value('statusDraft');
  String get statusFinalized => _value('statusFinalized');
  String get statusVoided => _value('statusVoided');
  String get openingBalance => _value('openingBalance');
  String get advancesTotal => _value('advancesTotal');
  String get driverPaidTripExpenses => _value('driverPaidTripExpenses');
  String get returnedCash => _value('returnedCash');
  String get deductionsTotal => _value('deductionsTotal');
  String get settlementDeductionsTotal => _value('settlementDeductionsTotal');
  String get netSalary => _value('netSalary');
  String get closingBalance => _value('closingBalance');
  String get driverOwesCompany => _value('driverOwesCompany');
  String get companyOwesDriver => _value('companyOwesDriver');
  String get balanceSettled => _value('balanceSettled');
  String get period => _value('period');
  String get status => _value('status');
  String get createdAt => _value('createdAt');
  String get finalizedAt => _value('finalizedAt');
  String get voidedAt => _value('voidedAt');
  String get voidReason => _value('voidReason');
  String get unknownDriver => _value('unknownDriver');
  String get finalize => _value('finalize');
  String get finalizing => _value('finalizing');
  String get finalizeTitle => _value('finalizeTitle');
  String get finalizeMessage => _value('finalizeMessage');
  String get voidAction => _value('void');
  String get voiding => _value('voiding');
  String get voidTitle => _value('voidTitle');
  String get voidMessage => _value('voidMessage');
  String get voidReasonRequired => _value('voidReasonRequired');
  String get activityTimeline => _value('activityTimeline');
  String get loadingActivity => _value('loadingActivity');
  String get noActivity => _value('noActivity');
  String get auditCreated => _value('auditCreated');
  String get auditFinalized => _value('auditFinalized');
  String get auditVoided => _value('auditVoided');
  String get itemAdvance => _value('itemAdvance');
  String get itemDeduction => _value('itemDeduction');
  String get itemTripExpense => _value('itemTripExpense');
  String get itemManualAdjustment => _value('itemManualAdjustment');
  String get directionCompanyToDriver => _value('directionCompanyToDriver');
  String get directionDriverToCompany => _value('directionDriverToCompany');
  String get directionNeutral => _value('directionNeutral');
  String get permissionViewFailure => _value('permissionViewFailure');
  String get permissionManageFailure => _value('permissionManageFailure');
  String get settlementIdRequiredFailure =>
      _value('settlementIdRequiredFailure');
  String get periodInvalidFailure => _value('periodInvalidFailure');
  String get amountNegativeFailure => _value('amountNegativeFailure');
  String get netSalaryNegativeFailure => _value('netSalaryNegativeFailure');
  String get voidReasonRequiredFailure => _value('voidReasonRequiredFailure');
  String get loadFailed => _value('loadFailed');
  String get previewFailed => _value('previewFailed');
  String get detailsFailed => _value('detailsFailed');
  String get draftCreated => _value('draftCreated');
  String get settlementFinalized => _value('settlementFinalized');
  String get settlementVoided => _value('settlementVoided');

  String labelValue(String label, String value) => _value(
    'labelValue',
  ).replaceFirst('{label}', label).replaceFirst('{value}', value);

  String periodValue(String start, String end) => _value(
    'periodValue',
  ).replaceFirst('{start}', start).replaceFirst('{end}', end);

  String auditHeader(String actor, String role, String dateTime) =>
      _value('auditHeader')
          .replaceFirst('{actor}', actor)
          .replaceFirst('{role}', role)
          .replaceFirst('{dateTime}', dateTime);

  static const Map<String, String> _en = {
    'appShellLabel': 'Driver settlements',
    'appShellDescription':
        'Close driver custody balances and prepare salary settlements.',
    'title': 'Driver settlements',
    'addDraft': 'New settlement',
    'searchHint': 'Search driver, period, status, amount, or notes',
    'allDrivers': 'All drivers',
    'allStatuses': 'All statuses',
    'showVoided': 'Show voided',
    'noSettlements': 'No driver settlements found.',
    'noMatchingSettlements': 'No driver settlements match the current filters.',
    'details': 'Details',
    'newDraftTitle': 'Create driver settlement draft',
    'driverLabel': 'Driver',
    'driverRequired': 'Select a driver.',
    'periodStart': 'Period start',
    'periodEnd': 'Period end',
    'periodInvalid': 'Period start must be on or before period end.',
    'grossSalary': 'Gross salary',
    'salaryDeductions': 'Salary deductions',
    'balanceDeduction': 'Driver balance deduction',
    'settlementDeductions': 'Settlement deductions',
    'notes': 'Notes',
    'nonNegativeAmount': 'Enter a valid non-negative amount.',
    'calculatePreview': 'Calculate preview',
    'calculatingPreview': 'Calculating...',
    'saveDraft': 'Save draft',
    'savingDraft': 'Saving...',
    'previewTitle': 'Settlement preview',
    'calculationBreakdown': 'Calculation breakdown',
    'sourceItems': 'Source items',
    'noSourceItems': 'No source movements were found for this period.',
    'statusDraft': 'Draft',
    'statusFinalized': 'Finalized',
    'statusVoided': 'Voided',
    'openingBalance': 'Opening driver balance',
    'advancesTotal': 'Advances',
    'driverPaidTripExpenses': 'Driver-paid trip expenses',
    'returnedCash': 'Returned cash',
    'deductionsTotal': 'Driver finance deductions',
    'settlementDeductionsTotal': 'Settlement deductions',
    'netSalary': 'Net salary payable',
    'closingBalance': 'Closing driver balance',
    'driverOwesCompany': 'Driver owes company',
    'companyOwesDriver': 'Company owes driver',
    'balanceSettled': 'Balance settled',
    'period': 'Period',
    'status': 'Status',
    'createdAt': 'Created at',
    'finalizedAt': 'Finalized at',
    'voidedAt': 'Voided at',
    'voidReason': 'Void reason',
    'unknownDriver': 'Unknown driver',
    'finalize': 'Finalize',
    'finalizing': 'Finalizing...',
    'finalizeTitle': 'Finalize settlement',
    'finalizeMessage':
        'Finalize this draft? Finalized settlements cannot be edited.',
    'void': 'Void',
    'voiding': 'Voiding...',
    'voidTitle': 'Void settlement',
    'voidMessage':
        'Void this settlement? It will remain in the financial history.',
    'voidReasonRequired': 'Void reason is required.',
    'activityTimeline': 'Activity timeline',
    'loadingActivity': 'Loading activity...',
    'noActivity': 'No settlement activity found.',
    'auditCreated': 'Settlement draft created',
    'auditFinalized': 'Settlement finalized',
    'auditVoided': 'Settlement voided',
    'itemAdvance': 'Driver advance',
    'itemDeduction': 'Driver deduction',
    'itemTripExpense': 'Driver-paid trip expense',
    'itemManualAdjustment': 'Manual adjustment',
    'directionCompanyToDriver': 'Company to driver',
    'directionDriverToCompany': 'Driver to company',
    'directionNeutral': 'Neutral',
    'permissionViewFailure': 'This role cannot view driver settlements.',
    'permissionManageFailure': 'This role cannot manage driver settlements.',
    'settlementIdRequiredFailure': 'Driver settlement is required.',
    'periodInvalidFailure': 'The settlement period is invalid.',
    'amountNegativeFailure': 'Settlement amounts cannot be negative.',
    'netSalaryNegativeFailure': 'Net salary payable cannot be negative.',
    'voidReasonRequiredFailure': 'A void reason is required.',
    'loadFailed': 'Driver settlements could not be loaded.',
    'previewFailed': 'The settlement preview could not be calculated.',
    'detailsFailed': 'Settlement details could not be loaded.',
    'draftCreated': 'Settlement draft created.',
    'settlementFinalized': 'Settlement finalized.',
    'settlementVoided': 'Settlement voided.',
    'labelValue': '{label}: {value}',
    'periodValue': '{start} – {end}',
    'auditHeader': '{actor} • {role} • {dateTime}',
  };

  static const Map<String, String> _ar = {
    'appShellLabel': 'تسويات السائقين',
    'appShellDescription': 'إقفال عهد وأرصدة السائقين وتجهيز تسويات الرواتب.',
    'title': 'تسويات السائقين',
    'addDraft': 'تسوية جديدة',
    'searchHint': 'ابحث بالسائق أو الفترة أو الحالة أو المبلغ أو الملاحظات',
    'allDrivers': 'كل السائقين',
    'allStatuses': 'كل الحالات',
    'showVoided': 'إظهار الملغاة',
    'noSettlements': 'لا توجد تسويات سائقين.',
    'noMatchingSettlements': 'لا توجد تسويات مطابقة للفلاتر الحالية.',
    'details': 'التفاصيل',
    'newDraftTitle': 'إنشاء مسودة تسوية سائق',
    'driverLabel': 'السائق',
    'driverRequired': 'اختر السائق.',
    'periodStart': 'بداية الفترة',
    'periodEnd': 'نهاية الفترة',
    'periodInvalid': 'يجب أن تكون بداية الفترة قبل أو مساوية لنهايتها.',
    'grossSalary': 'إجمالي الراتب',
    'salaryDeductions': 'خصومات الراتب',
    'balanceDeduction': 'خصم من رصيد السائق',
    'settlementDeductions': 'خصومات التسوية',
    'notes': 'ملاحظات',
    'nonNegativeAmount': 'أدخل مبلغًا صحيحًا غير سالب.',
    'calculatePreview': 'حساب المعاينة',
    'calculatingPreview': 'جاري الحساب...',
    'saveDraft': 'حفظ المسودة',
    'savingDraft': 'جاري الحفظ...',
    'previewTitle': 'معاينة التسوية',
    'calculationBreakdown': 'تفاصيل الحساب',
    'sourceItems': 'مصادر التسوية',
    'noSourceItems': 'لا توجد حركات مصدر لهذه الفترة.',
    'statusDraft': 'مسودة',
    'statusFinalized': 'نهائية',
    'statusVoided': 'ملغاة',
    'openingBalance': 'رصيد السائق الافتتاحي',
    'advancesTotal': 'السلف',
    'driverPaidTripExpenses': 'مصروفات الرحلات المدفوعة بواسطة السائق',
    'returnedCash': 'النقدية المرتجعة',
    'deductionsTotal': 'خصومات الحركات المالية',
    'settlementDeductionsTotal': 'خصومات التسوية',
    'netSalary': 'صافي الراتب المستحق',
    'closingBalance': 'رصيد السائق الختامي',
    'driverOwesCompany': 'السائق مدين للشركة',
    'companyOwesDriver': 'الشركة مدينة للسائق',
    'balanceSettled': 'الرصيد مُسوّى',
    'period': 'الفترة',
    'status': 'الحالة',
    'createdAt': 'تاريخ الإنشاء',
    'finalizedAt': 'تاريخ الاعتماد',
    'voidedAt': 'تاريخ الإلغاء',
    'voidReason': 'سبب الإلغاء',
    'unknownDriver': 'سائق غير معروف',
    'finalize': 'اعتماد',
    'finalizing': 'جاري الاعتماد...',
    'finalizeTitle': 'اعتماد التسوية',
    'finalizeMessage':
        'هل تريد اعتماد هذه المسودة؟ لا يمكن تعديل التسويات المعتمدة.',
    'void': 'إلغاء',
    'voiding': 'جاري الإلغاء...',
    'voidTitle': 'إلغاء التسوية',
    'voidMessage': 'هل تريد إلغاء هذه التسوية؟ ستظل محفوظة في السجل المالي.',
    'voidReasonRequired': 'سبب الإلغاء مطلوب.',
    'activityTimeline': 'سجل النشاط',
    'loadingActivity': 'جاري تحميل النشاط...',
    'noActivity': 'لا يوجد نشاط لهذه التسوية.',
    'auditCreated': 'تم إنشاء مسودة التسوية',
    'auditFinalized': 'تم اعتماد التسوية',
    'auditVoided': 'تم إلغاء التسوية',
    'itemAdvance': 'سلفة سائق',
    'itemDeduction': 'خصم سائق',
    'itemTripExpense': 'مصروف رحلة مدفوع بواسطة السائق',
    'itemManualAdjustment': 'تسوية يدوية',
    'directionCompanyToDriver': 'من الشركة إلى السائق',
    'directionDriverToCompany': 'من السائق إلى الشركة',
    'directionNeutral': 'محايد',
    'permissionViewFailure': 'هذا الدور لا يمكنه عرض تسويات السائقين.',
    'permissionManageFailure': 'هذا الدور لا يمكنه إدارة تسويات السائقين.',
    'settlementIdRequiredFailure': 'تسوية السائق مطلوبة.',
    'periodInvalidFailure': 'فترة التسوية غير صحيحة.',
    'amountNegativeFailure': 'مبالغ التسوية لا يمكن أن تكون سالبة.',
    'netSalaryNegativeFailure': 'صافي الراتب المستحق لا يمكن أن يكون سالبًا.',
    'voidReasonRequiredFailure': 'سبب الإلغاء مطلوب.',
    'loadFailed': 'تعذر تحميل تسويات السائقين.',
    'previewFailed': 'تعذر حساب معاينة التسوية.',
    'detailsFailed': 'تعذر تحميل تفاصيل التسوية.',
    'draftCreated': 'تم إنشاء مسودة التسوية.',
    'settlementFinalized': 'تم اعتماد التسوية.',
    'settlementVoided': 'تم إلغاء التسوية.',
    'labelValue': '{label}: {value}',
    'periodValue': '{start} – {end}',
    'auditHeader': '{actor} • {role} • {dateTime}',
  };
}

extension DriverSettlementsBuildContextX on BuildContext {
  DriverSettlementsLocalizations get driverSettlementsL10n =>
      DriverSettlementsLocalizations.forLocale(Localizations.localeOf(this));
}
