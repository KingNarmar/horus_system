import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/expenses/domain/entities/trip_expense_paid_by.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/reports/presentation/cubit/report_type.dart';
import 'package:horus_system/features/reports/presentation/localization/reports_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  group('ReportsLocalizations', () {
    final english = ReportsLocalizations(AppLocalizationsEn());
    final arabic = ReportsLocalizations(AppLocalizationsAr());

    test(
      'delegates representative static labels to generated localization',
      () {
        expect(english.title, 'Reports');
        expect(arabic.title, 'التقارير');

        expect(english.totalExpenses, 'Total expenses');
        expect(arabic.totalExpenses, 'إجمالي المصروفات');

        expect(english.totalOutstanding, 'Total outstanding');
        expect(arabic.totalOutstanding, 'إجمالي المستحق');
      },
    );

    test('maps every report type through generated localization', () {
      expect(english.reportTypeLabel(ReportType.dailyTrips), 'Daily trips');
      expect(
        english.reportTypeLabel(ReportType.tripsByCustomer),
        'Trips by customer',
      );
      expect(
        english.reportTypeLabel(ReportType.tripsByDriver),
        'Trips by driver',
      );
      expect(
        english.reportTypeLabel(ReportType.tripsByTractorHead),
        'Trips by tractor head',
      );
      expect(
        english.reportTypeLabel(ReportType.tripsByTrailer),
        'Trips by trailer',
      );
      expect(english.reportTypeLabel(ReportType.tripExpenses), 'Trip expenses');
      expect(
        english.reportTypeLabel(ReportType.tripNetProfit),
        'Trip net profit',
      );
      expect(english.reportTypeLabel(ReportType.openInvoices), 'Open invoices');

      expect(arabic.reportTypeLabel(ReportType.dailyTrips), 'الرحلات اليومية');
      expect(
        arabic.reportTypeLabel(ReportType.tripsByCustomer),
        'الرحلات حسب العميل',
      );
      expect(
        arabic.reportTypeLabel(ReportType.tripsByDriver),
        'الرحلات حسب السائق',
      );
      expect(
        arabic.reportTypeLabel(ReportType.tripsByTractorHead),
        'الرحلات حسب رأس الجرار',
      );
      expect(
        arabic.reportTypeLabel(ReportType.tripsByTrailer),
        'الرحلات حسب المقطورة',
      );
      expect(
        arabic.reportTypeLabel(ReportType.tripExpenses),
        'مصروفات الرحلات',
      );
      expect(
        arabic.reportTypeLabel(ReportType.tripNetProfit),
        'صافي ربح الرحلات',
      );
      expect(
        arabic.reportTypeLabel(ReportType.openInvoices),
        'الفواتير المفتوحة',
      );
    });

    test('maps every paid-by value through generated localization', () {
      expect(english.paidByLabel(TripExpensePaidBy.company), 'Company');
      expect(
        english.paidByLabel(TripExpensePaidBy.driverAdvance),
        'Driver advance',
      );
      expect(english.paidByLabel(TripExpensePaidBy.driverCash), 'Driver cash');
      expect(english.paidByLabel(TripExpensePaidBy.customer), 'Customer');
      expect(english.paidByLabel(TripExpensePaidBy.other), 'Other');

      expect(arabic.paidByLabel(TripExpensePaidBy.company), 'الشركة');
      expect(
        arabic.paidByLabel(TripExpensePaidBy.driverAdvance),
        'عهدة السائق',
      );
      expect(arabic.paidByLabel(TripExpensePaidBy.driverCash), 'دفع السائق');
      expect(arabic.paidByLabel(TripExpensePaidBy.customer), 'العميل');
      expect(arabic.paidByLabel(TripExpensePaidBy.other), 'أخرى');
    });

    test('maps every invoice status used by reports', () {
      expect(english.invoiceStatusLabel(InvoiceStatus.draft), 'Draft');
      expect(english.invoiceStatusLabel(InvoiceStatus.issued), 'Issued');
      expect(
        english.invoiceStatusLabel(InvoiceStatus.partiallyPaid),
        'Partially paid',
      );
      expect(english.invoiceStatusLabel(InvoiceStatus.paid), 'Paid');
      expect(english.invoiceStatusLabel(InvoiceStatus.cancelled), 'Cancelled');

      expect(arabic.invoiceStatusLabel(InvoiceStatus.draft), 'مسودة');
      expect(arabic.invoiceStatusLabel(InvoiceStatus.issued), 'صادرة');
      expect(
        arabic.invoiceStatusLabel(InvoiceStatus.partiallyPaid),
        'مدفوعة جزئيًا',
      );
      expect(arabic.invoiceStatusLabel(InvoiceStatus.paid), 'مدفوعة');
      expect(arabic.invoiceStatusLabel(InvoiceStatus.cancelled), 'ملغاة');
    });

    test('preserves placeholder-based report wording', () {
      expect(english.groupTrips(3), '3 trips');
      expect(arabic.groupTrips(3), '3 رحلة');

      expect(
        english.dateRange('2026-08-01', '2026-08-31'),
        'Period: 2026-08-01 — 2026-08-31',
      );
      expect(
        arabic.dateRange('2026-08-01', '2026-08-31'),
        'الفترة: 2026-08-01 — 2026-08-31',
      );
    });

    test('preserves representative failure messages', () {
      expect(
        english.permissionFailure,
        'This role cannot view the selected report.',
      );
      expect(
        arabic.permissionFailure,
        'هذا الدور غير مسموح له بعرض التقرير المحدد.',
      );

      expect(
        english.invalidDateRangeFailure,
        'The from date cannot be after the to date.',
      );
      expect(
        arabic.invalidDateRangeFailure,
        'يجب ألا يكون تاريخ البداية بعد تاريخ النهاية.',
      );

      expect(english.loadFailed, 'The report could not be loaded.');
      expect(arabic.loadFailed, 'تعذر تحميل التقرير.');
    });
  });
}
