import 'package:flutter/widgets.dart';

import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../cubit/report_type.dart';

final class ReportsLocalizations {
  final bool _isArabic;

  const ReportsLocalizations._(this._isArabic);

  factory ReportsLocalizations.forLocale(Locale locale) {
    return ReportsLocalizations._(locale.languageCode == 'ar');
  }

  String get title => _isArabic ? 'التقارير' : 'Reports';
  String get reportLabel => _isArabic ? 'التقرير' : 'Report';
  String get fromDate => _isArabic ? 'من تاريخ' : 'From date';
  String get toDate => _isArabic ? 'إلى تاريخ' : 'To date';
  String get selectDate => _isArabic ? 'اختر تاريخًا' : 'Select date';
  String get applyFilters => _isArabic ? 'تطبيق' : 'Apply';
  String get clearFilters => _isArabic ? 'مسح التواريخ' : 'Clear dates';
  String get loading =>
      _isArabic ? 'جاري تحميل التقرير...' : 'Loading report...';
  String get retry => _isArabic ? 'إعادة المحاولة' : 'Retry';
  String get noRows => _isArabic
      ? 'لا توجد بيانات للفترة المحددة.'
      : 'No data for the selected period.';
  String get noAccess => _isArabic
      ? 'لا توجد تقارير متاحة لهذا الدور.'
      : 'No reports are available for this role.';
  String get unassigned => _isArabic ? 'غير مسند' : 'Unassigned';
  String get allDates => _isArabic ? 'كل التواريخ' : 'All dates';
  String get notAvailable => _isArabic ? 'غير متاح' : 'Not available';

  String get trip => _isArabic ? 'الرحلة' : 'Trip';
  String get date => _isArabic ? 'التاريخ' : 'Date';
  String get customer => _isArabic ? 'العميل' : 'Customer';
  String get driver => _isArabic ? 'السائق' : 'Driver';
  String get tractorHead => _isArabic ? 'رأس الجرار' : 'Tractor head';
  String get trailer => _isArabic ? 'المقطورة' : 'Trailer';
  String get route => _isArabic ? 'المسار' : 'Route';
  String get status => _isArabic ? 'الحالة' : 'Status';
  String get tripsCount => _isArabic ? 'عدد الرحلات' : 'Trips';
  String get loadingOrder => _isArabic ? 'أمر التحميل' : 'Loading order';
  String get waybill => _isArabic ? 'البوليصة' : 'Waybill';

  String get expense => _isArabic ? 'المصروف' : 'Expense';
  String get paidBy => _isArabic ? 'الدافع' : 'Paid by';
  String get amount => _isArabic ? 'المبلغ' : 'Amount';
  String get totalExpenses =>
      _isArabic ? 'إجمالي المصروفات' : 'Total expenses';
  String get freight => _isArabic ? 'سعر النقل' : 'Freight';
  String get netProfit => _isArabic ? 'صافي الربح' : 'Net profit';
  String get totalFreight => _isArabic ? 'إجمالي النقل' : 'Total freight';
  String get totalNetProfit =>
      _isArabic ? 'إجمالي صافي الربح' : 'Total net profit';

  String get invoice => _isArabic ? 'الفاتورة' : 'Invoice';
  String get issueDate => _isArabic ? 'تاريخ الإصدار' : 'Issue date';
  String get dueDate => _isArabic ? 'تاريخ الاستحقاق' : 'Due date';
  String get total => _isArabic ? 'الإجمالي' : 'Total';
  String get paid => _isArabic ? 'المدفوع' : 'Paid';
  String get remaining => _isArabic ? 'المتبقي' : 'Remaining';
  String get totalOutstanding =>
      _isArabic ? 'إجمالي المستحق' : 'Total outstanding';

  String reportTypeLabel(ReportType type) {
    return switch (type) {
      ReportType.dailyTrips =>
        _isArabic ? 'الرحلات اليومية' : 'Daily trips',
      ReportType.tripsByCustomer =>
        _isArabic ? 'الرحلات حسب العميل' : 'Trips by customer',
      ReportType.tripsByDriver =>
        _isArabic ? 'الرحلات حسب السائق' : 'Trips by driver',
      ReportType.tripsByTractorHead =>
        _isArabic ? 'الرحلات حسب رأس الجرار' : 'Trips by tractor head',
      ReportType.tripsByTrailer =>
        _isArabic ? 'الرحلات حسب المقطورة' : 'Trips by trailer',
      ReportType.tripExpenses =>
        _isArabic ? 'مصروفات الرحلات' : 'Trip expenses',
      ReportType.tripNetProfit =>
        _isArabic ? 'صافي ربح الرحلات' : 'Trip net profit',
      ReportType.openInvoices =>
        _isArabic ? 'الفواتير المفتوحة' : 'Open invoices',
    };
  }

  String groupTrips(int count) {
    return _isArabic ? '$count رحلة' : '$count trips';
  }

  String dateRange(String from, String to) {
    return _isArabic ? 'الفترة: $from — $to' : 'Period: $from — $to';
  }

  String paidByLabel(TripExpensePaidBy value) {
    return switch (value) {
      TripExpensePaidBy.company => _isArabic ? 'الشركة' : 'Company',
      TripExpensePaidBy.driverAdvance =>
        _isArabic ? 'عهدة السائق' : 'Driver advance',
      TripExpensePaidBy.driverCash =>
        _isArabic ? 'دفع السائق' : 'Driver cash',
      TripExpensePaidBy.customer => _isArabic ? 'العميل' : 'Customer',
      TripExpensePaidBy.other => _isArabic ? 'أخرى' : 'Other',
    };
  }

  String invoiceStatusLabel(InvoiceStatus status) {
    return switch (status) {
      InvoiceStatus.draft => _isArabic ? 'مسودة' : 'Draft',
      InvoiceStatus.issued => _isArabic ? 'صادرة' : 'Issued',
      InvoiceStatus.partiallyPaid =>
        _isArabic ? 'مدفوعة جزئيًا' : 'Partially paid',
      InvoiceStatus.paid => _isArabic ? 'مدفوعة' : 'Paid',
      InvoiceStatus.cancelled => _isArabic ? 'ملغاة' : 'Cancelled',
    };
  }

  String get permissionFailure => _isArabic
      ? 'هذا الدور غير مسموح له بعرض التقرير المحدد.'
      : 'This role cannot view the selected report.';
  String get invalidDateRangeFailure => _isArabic
      ? 'يجب ألا يكون تاريخ البداية بعد تاريخ النهاية.'
      : 'The from date cannot be after the to date.';
  String get regionalSettingsFailure => _isArabic
      ? 'اضبط عملة الشركة والمنطقة الزمنية للعمل أولًا.'
      : 'Configure the company currency and business timezone first.';
  String get companyNotFoundFailure => _isArabic
      ? 'تعذر العثور على الشركة الحالية.'
      : 'The current company could not be found.';
  String get sourceInvalidFailure => _isArabic
      ? 'بيانات التقرير غير متسقة. أعد التحميل ثم حاول مرة أخرى.'
      : 'The report data is inconsistent. Reload and try again.';
  String get currencyMismatchFailure => _isArabic
      ? 'البيانات المالية للتقرير لا تطابق عملة الشركة.'
      : 'Report financial data does not match the company currency.';
  String get financialDataInvalidFailure => _isArabic
      ? 'تحتوي بيانات التقرير المالية على مبلغ أو رصيد غير صالح.'
      : 'Report financial data contains an invalid amount or balance.';
  String get invoiceBalanceInvalidFailure => _isArabic
      ? 'رصيد إحدى الفواتير غير متسق مع حالة الفاتورة ومدفوعاتها.'
      : 'An invoice balance is inconsistent with its status and payments.';
  String get loadFailed =>
      _isArabic ? 'تعذر تحميل التقرير.' : 'The report could not be loaded.';
}

extension ReportsLocalizationsBuildContextX on BuildContext {
  ReportsLocalizations get reportsL10n {
    return ReportsLocalizations.forLocale(Localizations.localeOf(this));
  }
}
