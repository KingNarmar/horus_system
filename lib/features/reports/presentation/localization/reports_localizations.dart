import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../cubit/report_type.dart';

final class ReportsLocalizations {
  final AppLocalizations _l10n;

  const ReportsLocalizations(this._l10n);

  String get title => _l10n.reportsTitle;
  String get reportLabel => _l10n.reportsReportLabel;
  String get fromDate => _l10n.reportsFromDate;
  String get toDate => _l10n.reportsToDate;
  String get selectDate => _l10n.reportsSelectDate;
  String get applyFilters => _l10n.reportsApplyFilters;
  String get clearFilters => _l10n.reportsClearFilters;
  String get loading => _l10n.reportsLoading;
  String get retry => _l10n.reportsRetry;
  String get noRows => _l10n.reportsNoRows;
  String get noAccess => _l10n.reportsNoAccess;
  String get unassigned => _l10n.reportsUnassigned;
  String get allDates => _l10n.reportsAllDates;
  String get notAvailable => _l10n.reportsNotAvailable;

  String get trip => _l10n.reportsTrip;
  String get date => _l10n.reportsDate;
  String get customer => _l10n.reportsCustomer;
  String get driver => _l10n.reportsDriver;
  String get tractorHead => _l10n.reportsTractorHead;
  String get trailer => _l10n.reportsTrailer;
  String get route => _l10n.reportsRoute;
  String get status => _l10n.reportsStatus;
  String get tripsCount => _l10n.reportsTripsCount;
  String get loadingOrder => _l10n.reportsLoadingOrder;
  String get waybill => _l10n.reportsWaybill;

  String get expense => _l10n.reportsExpense;
  String get paidBy => _l10n.reportsPaidBy;
  String get amount => _l10n.reportsAmount;
  String get totalExpenses => _l10n.reportsTotalExpenses;
  String get freight => _l10n.reportsFreight;
  String get netProfit => _l10n.reportsNetProfit;
  String get totalFreight => _l10n.reportsTotalFreight;
  String get totalNetProfit => _l10n.reportsTotalNetProfit;

  String get invoice => _l10n.reportsInvoice;
  String get issueDate => _l10n.reportsIssueDate;
  String get dueDate => _l10n.reportsDueDate;
  String get total => _l10n.reportsTotal;
  String get paid => _l10n.reportsPaid;
  String get remaining => _l10n.reportsRemaining;
  String get totalOutstanding => _l10n.reportsTotalOutstanding;

  String reportTypeLabel(ReportType type) {
    return switch (type) {
      ReportType.dailyTrips => _l10n.reportsTypeDailyTrips,
      ReportType.tripsByCustomer => _l10n.reportsTypeTripsByCustomer,
      ReportType.tripsByDriver => _l10n.reportsTypeTripsByDriver,
      ReportType.tripsByTractorHead => _l10n.reportsTypeTripsByTractorHead,
      ReportType.tripsByTrailer => _l10n.reportsTypeTripsByTrailer,
      ReportType.tripExpenses => _l10n.reportsTypeTripExpenses,
      ReportType.tripNetProfit => _l10n.reportsTypeTripNetProfit,
      ReportType.openInvoices => _l10n.reportsTypeOpenInvoices,
    };
  }

  String groupTrips(int count) => _l10n.reportsGroupTrips(count);

  String dateRange(String from, String to) {
    return _l10n.reportsDateRange(from, to);
  }

  String paidByLabel(TripExpensePaidBy value) {
    return switch (value) {
      TripExpensePaidBy.company => _l10n.reportsPaidByCompany,
      TripExpensePaidBy.driverAdvance => _l10n.reportsPaidByDriverAdvance,
      TripExpensePaidBy.driverCash => _l10n.reportsPaidByDriverCash,
      TripExpensePaidBy.customer => _l10n.reportsPaidByCustomer,
      TripExpensePaidBy.other => _l10n.reportsPaidByOther,
    };
  }

  String invoiceStatusLabel(InvoiceStatus status) {
    return switch (status) {
      InvoiceStatus.draft => _l10n.reportsInvoiceStatusDraft,
      InvoiceStatus.issued => _l10n.reportsInvoiceStatusIssued,
      InvoiceStatus.partiallyPaid => _l10n.reportsInvoiceStatusPartiallyPaid,
      InvoiceStatus.paid => _l10n.reportsInvoiceStatusPaid,
      InvoiceStatus.cancelled => _l10n.reportsInvoiceStatusCancelled,
    };
  }

  String get permissionFailure => _l10n.reportsPermissionFailure;
  String get invalidDateRangeFailure => _l10n.reportsInvalidDateRangeFailure;
  String get regionalSettingsFailure => _l10n.reportsRegionalSettingsFailure;
  String get companyNotFoundFailure => _l10n.reportsCompanyNotFoundFailure;
  String get sourceInvalidFailure => _l10n.reportsSourceInvalidFailure;
  String get currencyMismatchFailure => _l10n.reportsCurrencyMismatchFailure;
  String get financialDataInvalidFailure =>
      _l10n.reportsFinancialDataInvalidFailure;
  String get invoiceBalanceInvalidFailure =>
      _l10n.reportsInvoiceBalanceInvalidFailure;
  String get loadFailed => _l10n.reportsLoadFailed;
}

extension ReportsLocalizationsBuildContextX on BuildContext {
  ReportsLocalizations get reportsL10n {
    return ReportsLocalizations(AppLocalizations.of(this));
  }
}
