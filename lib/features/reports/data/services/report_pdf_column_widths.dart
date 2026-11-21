import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/report_export_table.dart';
import '../constants/report_pdf_style.dart';

/// Give dates, references and descriptive columns room before PDF layout.
abstract final class ReportPdfColumnWidths {
  static Map<int, pw.TableColumnWidth> forColumns(
    List<ReportExportColumn> columns,
  ) => {
    for (var index = 0; index < columns.length; index++)
      index: pw.FlexColumnWidth(_flexFor(columns[index])),
  };

  static double _flexFor(ReportExportColumn column) => switch (column) {
    ReportExportColumn.trip => ReportPdfStyle.tripColumnFlex,
    ReportExportColumn.date ||
    ReportExportColumn.issueDate ||
    ReportExportColumn.dueDate => ReportPdfStyle.dateColumnFlex,
    ReportExportColumn.customer ||
    ReportExportColumn.driver ||
    ReportExportColumn.expense ||
    ReportExportColumn.group => ReportPdfStyle.descriptionColumnFlex,
    ReportExportColumn.route => ReportPdfStyle.routeColumnFlex,
    ReportExportColumn.tractorHead ||
    ReportExportColumn.trailer ||
    ReportExportColumn.invoice => ReportPdfStyle.identifierColumnFlex,
    ReportExportColumn.status => ReportPdfStyle.statusColumnFlex,
    ReportExportColumn.amount ||
    ReportExportColumn.freight ||
    ReportExportColumn.totalExpenses ||
    ReportExportColumn.netProfit ||
    ReportExportColumn.total ||
    ReportExportColumn.paid ||
    ReportExportColumn.remaining ||
    ReportExportColumn.totalFreight ||
    ReportExportColumn.totalNetProfit ||
    ReportExportColumn.totalOutstanding => ReportPdfStyle.moneyColumnFlex,
    ReportExportColumn.tripCount ||
    ReportExportColumn.paidBy => ReportPdfStyle.defaultColumnFlex,
  };
}
