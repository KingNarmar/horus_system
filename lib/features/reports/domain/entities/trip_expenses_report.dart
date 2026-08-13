import '../../../../core/domain/value_objects/money.dart';
import '../../../expenses/domain/entities/trip_expense_paid_by.dart';
import 'report_source_metadata.dart';

final class TripExpenseReportRow {
  final String expenseId;
  final DateTime expenseDate;
  final String tripId;
  final String? tripNumber;
  final DateTime tripDate;
  final String customerId;
  final String customerName;
  final String loadingLocation;
  final String unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final String? expenseTypeId;
  final String expenseName;
  final TripExpensePaidBy paidBy;
  final Money amount;

  const TripExpenseReportRow({
    required this.expenseId,
    required this.expenseDate,
    required this.tripId,
    required this.tripNumber,
    required this.tripDate,
    required this.customerId,
    required this.customerName,
    required this.loadingLocation,
    required this.unloadingLocation,
    required this.loadingOrderNumber,
    required this.waybillNumber,
    required this.expenseTypeId,
    required this.expenseName,
    required this.paidBy,
    required this.amount,
  });
}

final class TripExpensesReportSource {
  final ReportSourceMetadata metadata;
  final int precisionLossCount;
  final int negativeAmountCount;
  final List<TripExpenseReportRow> rows;

  TripExpensesReportSource({
    required this.metadata,
    required this.precisionLossCount,
    required this.negativeAmountCount,
    required List<TripExpenseReportRow> rows,
  }) : rows = List.unmodifiable(rows);
}

final class TripExpensesReport {
  final ReportSourceMetadata metadata;
  final List<TripExpenseReportRow> rows;
  final Money totalExpenses;

  TripExpensesReport({
    required this.metadata,
    required List<TripExpenseReportRow> rows,
    required this.totalExpenses,
  }) : rows = List.unmodifiable(rows);
}
