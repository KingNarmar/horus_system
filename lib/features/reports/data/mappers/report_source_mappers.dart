import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../trips/domain/entities/trip_status.dart';
import '../../domain/entities/open_invoices_report.dart';
import '../../domain/entities/operational_trip_report.dart';
import '../../domain/entities/report_source_metadata.dart';
import '../../domain/entities/trip_expenses_report.dart';
import '../../domain/entities/trip_net_profit_report.dart';
import '../models/open_invoices_report_source_model.dart';
import '../models/operational_report_source_model.dart';
import '../models/report_source_metadata_model.dart';
import '../models/trip_expenses_report_source_model.dart';
import '../models/trip_net_profit_report_source_model.dart';

extension ReportSourceMetadataModelMapper on ReportSourceMetadataModel {
  ReportSourceMetadata toEntity() {
    final currency = CurrencyCode.tryParse(baseCurrencyCode);
    if (currency == null) {
      throw const FormatException('Invalid report currency.');
    }
    return ReportSourceMetadata(
      companyId: companyId,
      currency: currency,
      baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      businessTimezone: businessTimezone,
      businessDate: businessDate,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}

extension OperationalReportSourceModelMapper on OperationalReportSourceModel {
  OperationalTripReportSource toEntity() {
    return OperationalTripReportSource(
      metadata: metadata.toEntity(),
      rows: rows.map((row) {
        return OperationalTripReportRow(
          tripId: row.tripId,
          tripNumber: row.tripNumber,
          operationalDate: row.operationalDate,
          status: _tripStatus(row.status),
          customerId: row.customerId,
          customerName: row.customerName,
          driverId: row.driverId,
          driverName: row.driverName,
          tractorHeadId: row.tractorHeadId,
          tractorHeadPlateNumber: row.tractorHeadPlateNumber,
          trailerId: row.trailerId,
          trailerPlateNumber: row.trailerPlateNumber,
          routeId: row.routeId,
          loadingLocation: row.loadingLocation,
          unloadingLocation: row.unloadingLocation,
          loadingOrderNumber: row.loadingOrderNumber,
          waybillNumber: row.waybillNumber,
          cargoType: row.cargoType,
          quantityTons: row.quantityTons,
        );
      }).toList(growable: false),
    );
  }
}

extension TripExpensesReportSourceModelMapper on TripExpensesReportSourceModel {
  TripExpensesReportSource toEntity() {
    final reportMetadata = metadata.toEntity();
    return TripExpensesReportSource(
      metadata: reportMetadata,
      precisionLossCount: precisionLossCount,
      negativeAmountCount: negativeAmountCount,
      rows: rows.map((row) {
        return TripExpenseReportRow(
          expenseId: row.expenseId,
          expenseDate: row.expenseDate,
          tripId: row.tripId,
          tripNumber: row.tripNumber,
          tripDate: row.tripDate,
          customerId: row.customerId,
          customerName: row.customerName,
          loadingLocation: row.loadingLocation,
          unloadingLocation: row.unloadingLocation,
          loadingOrderNumber: row.loadingOrderNumber,
          waybillNumber: row.waybillNumber,
          expenseTypeId: row.expenseTypeId,
          expenseName: row.expenseName,
          paidBy: _paidBy(row.paidBy),
          amount: Money(
            minorUnits: row.amountMinorUnits,
            currency: reportMetadata.currency,
          ),
        );
      }).toList(growable: false),
    );
  }
}

extension TripNetProfitReportSourceModelMapper
    on TripNetProfitReportSourceModel {
  TripNetProfitReportSource toEntity() {
    final reportMetadata = metadata.toEntity();
    return TripNetProfitReportSource(
      metadata: reportMetadata,
      freightPrecisionLossCount: freightPrecisionLossCount,
      negativeFreightCount: negativeFreightCount,
      expensePrecisionLossCount: expensePrecisionLossCount,
      negativeExpenseCount: negativeExpenseCount,
      trips: trips.map((trip) {
        return TripNetProfitSourceTrip(
          tripId: trip.tripId,
          tripNumber: trip.tripNumber,
          operationalDate: trip.operationalDate,
          status: _tripStatus(trip.status),
          customerId: trip.customerId,
          customerName: trip.customerName,
          driverId: trip.driverId,
          driverName: trip.driverName,
          tractorHeadId: trip.tractorHeadId,
          tractorHeadPlateNumber: trip.tractorHeadPlateNumber,
          trailerId: trip.trailerId,
          trailerPlateNumber: trip.trailerPlateNumber,
          loadingLocation: trip.loadingLocation,
          unloadingLocation: trip.unloadingLocation,
          loadingOrderNumber: trip.loadingOrderNumber,
          waybillNumber: trip.waybillNumber,
          freight: Money(
            minorUnits: trip.freightMinorUnits,
            currency: reportMetadata.currency,
          ),
        );
      }).toList(growable: false),
      expenses: expenses.map((expense) {
        return TripNetProfitSourceExpense(
          expenseId: expense.expenseId,
          tripId: expense.tripId,
          amount: Money(
            minorUnits: expense.amountMinorUnits,
            currency: reportMetadata.currency,
          ),
        );
      }).toList(growable: false),
    );
  }
}

extension OpenInvoicesReportSourceModelMapper on OpenInvoicesReportSourceModel {
  OpenInvoicesReportSource toEntity() {
    final reportMetadata = metadata.toEntity();
    return OpenInvoicesReportSource(
      metadata: reportMetadata,
      invoiceCurrencyMismatchCount: invoiceCurrencyMismatchCount,
      paymentCurrencyMismatchCount: paymentCurrencyMismatchCount,
      invalidInvoiceAmountCount: invalidInvoiceAmountCount,
      invalidPaymentAmountCount: invalidPaymentAmountCount,
      missingIssueDateCount: missingIssueDateCount,
      invoices: invoices.map((invoice) {
        final currency = CurrencyCode.tryParse(invoice.currencyCode);
        final status = InvoiceStatus.tryFromValue(invoice.status);
        if (currency == null || status == null) {
          throw const FormatException('Invalid invoice report source.');
        }
        return OpenInvoiceSourceInvoice(
          invoiceId: invoice.invoiceId,
          invoiceNumber: invoice.invoiceNumber,
          customerId: invoice.customerId,
          customerName: invoice.customerName,
          status: status,
          total: Money(
            minorUnits: invoice.totalMinorUnits,
            currency: currency,
          ),
          issueDate: invoice.issueDate,
          dueDate: invoice.dueDate,
          issuedAt: invoice.issuedAt,
        );
      }).toList(growable: false),
      payments: payments.map((payment) {
        final currency = CurrencyCode.tryParse(payment.currencyCode);
        if (currency == null) {
          throw const FormatException('Invalid payment report currency.');
        }
        return OpenInvoiceSourcePayment(
          paymentId: payment.paymentId,
          invoiceId: payment.invoiceId,
          amount: Money(
            minorUnits: payment.amountMinorUnits,
            currency: currency,
          ),
          paymentDate: payment.paymentDate,
          createdAt: payment.createdAt,
        );
      }).toList(growable: false),
    );
  }
}

TripStatus _tripStatus(String raw) {
  for (final status in TripStatus.values) {
    if (status.value == raw.trim().toLowerCase()) return status;
  }
  throw const FormatException('Invalid trip report status.');
}

TripExpensePaidBy _paidBy(String raw) {
  for (final paidBy in TripExpensePaidBy.values) {
    if (paidBy.value == raw.trim().toLowerCase()) return paidBy;
  }
  throw const FormatException('Invalid trip expense paid-by value.');
}
