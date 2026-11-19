import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../expenses/domain/entities/expense_funding_source.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../trips/domain/entities/trip_status.dart';

enum ReportExportColumn {
  group,
  tripCount,
  trip,
  date,
  customer,
  driver,
  tractorHead,
  trailer,
  route,
  status,
  expense,
  paidBy,
  amount,
  freight,
  totalExpenses,
  netProfit,
  invoice,
  issueDate,
  dueDate,
  total,
  paid,
  remaining,
  totalFreight,
  totalNetProfit,
  totalOutstanding,
}

sealed class ReportExportCell {
  const ReportExportCell();
}

final class ReportExportTextCell extends ReportExportCell {
  final String value;
  const ReportExportTextCell(this.value);
}

final class ReportExportDateCell extends ReportExportCell {
  final BusinessDate value;
  const ReportExportDateCell(this.value);
}

final class ReportExportCountCell extends ReportExportCell {
  final int value;
  const ReportExportCountCell(this.value);
}

final class ReportExportMoneyCell extends ReportExportCell {
  final Money value;
  const ReportExportMoneyCell(this.value);
}

final class ReportExportTripStatusCell extends ReportExportCell {
  final TripStatus value;
  const ReportExportTripStatusCell(this.value);
}

final class ReportExportInvoiceStatusCell extends ReportExportCell {
  final InvoiceStatus value;
  const ReportExportInvoiceStatusCell(this.value);
}

final class ReportExportFundingCell extends ReportExportCell {
  final ExpenseFundingSource value;
  const ReportExportFundingCell(this.value);
}

final class ReportExportOptionalDateCell extends ReportExportCell {
  final BusinessDate? value;
  const ReportExportOptionalDateCell(this.value);
}

final class ReportExportTotal {
  final ReportExportColumn label;
  final ReportExportCell value;

  const ReportExportTotal({required this.label, required this.value});
}

/// One typed projection for both PDF and future true XLSX renderers.
/// Money retains exact minor units; dates are never preformatted as strings.
final class ReportExportTable {
  final List<ReportExportColumn> columns;
  final List<List<ReportExportCell>> rows;
  final List<ReportExportTotal> totals;
  final int currencyFractionDigits;

  ReportExportTable({
    required List<ReportExportColumn> columns,
    required List<List<ReportExportCell>> rows,
    required List<ReportExportTotal> totals,
    required this.currencyFractionDigits,
  }) : columns = List.unmodifiable(columns),
       rows = List.unmodifiable(rows.map((row) => List<ReportExportCell>.unmodifiable(row))),
       totals = List.unmodifiable(totals);

  int get rowCount => rows.length;
}
