import '../../../../core/domain/value_objects/business_date.dart';
import 'report_model_parsing.dart';
import 'report_source_metadata_model.dart';

final class TripExpensesReportSourceModel {
  final ReportSourceMetadataModel metadata;
  final int precisionLossCount;
  final int negativeAmountCount;
  final int currencyMismatchCount;
  final List<TripExpenseRowModel> rows;

  TripExpensesReportSourceModel({
    required this.metadata,
    required this.precisionLossCount,
    required this.negativeAmountCount,
    required this.currencyMismatchCount,
    required List<TripExpenseRowModel> rows,
  }) : rows = List.unmodifiable(rows);

  factory TripExpensesReportSourceModel.fromMap(Map<String, dynamic> map) {
    final validation = requiredMap(map['validation'], 'validation');
    return TripExpensesReportSourceModel(
      metadata: ReportSourceMetadataModel.fromRoot(map),
      precisionLossCount: requiredInt(
        validation['precision_loss_count'],
        'precision_loss_count',
      ),
      negativeAmountCount: requiredInt(
        validation['negative_amount_count'],
        'negative_amount_count',
      ),
      currencyMismatchCount: requiredInt(
        validation['currency_mismatch_count'],
        'currency_mismatch_count',
      ),
      rows: requiredMapList(
        map['rows'],
        'rows',
      ).map(TripExpenseRowModel.fromMap).toList(growable: false),
    );
  }
}

final class TripExpenseRowModel {
  final String expenseId;
  final BusinessDate expenseDate;
  final String tripId;
  final String? tripNumber;
  final BusinessDate tripDate;
  final String customerId;
  final String customerName;
  final String loadingLocation;
  final String unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final String? expenseTypeId;
  final String expenseName;
  final String fundingSource;
  final int amountMinorUnits;

  const TripExpenseRowModel({
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
    required this.fundingSource,
    required this.amountMinorUnits,
  });

  factory TripExpenseRowModel.fromMap(Map<String, dynamic> map) {
    return TripExpenseRowModel(
      expenseId: requiredString(map['expense_id'], 'expense_id'),
      expenseDate: requiredDate(map['expense_date'], 'expense_date'),
      tripId: requiredString(map['trip_id'], 'trip_id'),
      tripNumber: optionalString(map['trip_number'], 'trip_number'),
      tripDate: requiredDate(map['trip_date'], 'trip_date'),
      customerId: requiredString(map['customer_id'], 'customer_id'),
      customerName: requiredString(map['customer_name'], 'customer_name'),
      loadingLocation: requiredString(
        map['loading_location'],
        'loading_location',
      ),
      unloadingLocation: requiredString(
        map['unloading_location'],
        'unloading_location',
      ),
      loadingOrderNumber: optionalString(
        map['loading_order_number'],
        'loading_order_number',
      ),
      waybillNumber: optionalString(map['waybill_number'], 'waybill_number'),
      expenseTypeId: optionalString(map['expense_type_id'], 'expense_type_id'),
      expenseName: requiredString(map['expense_name'], 'expense_name'),
      fundingSource: requiredString(map['paid_by'], 'paid_by'),
      amountMinorUnits: requiredInt(
        map['amount_minor_units'],
        'amount_minor_units',
      ),
    );
  }
}
