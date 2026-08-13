import 'report_model_parsing.dart';
import 'report_source_metadata_model.dart';

final class TripNetProfitReportSourceModel {
  final ReportSourceMetadataModel metadata;
  final int freightPrecisionLossCount;
  final int negativeFreightCount;
  final int expensePrecisionLossCount;
  final int negativeExpenseCount;
  final List<TripNetProfitTripModel> trips;
  final List<TripNetProfitExpenseModel> expenses;

  TripNetProfitReportSourceModel({
    required this.metadata,
    required this.freightPrecisionLossCount,
    required this.negativeFreightCount,
    required this.expensePrecisionLossCount,
    required this.negativeExpenseCount,
    required List<TripNetProfitTripModel> trips,
    required List<TripNetProfitExpenseModel> expenses,
  }) : trips = List.unmodifiable(trips),
       expenses = List.unmodifiable(expenses);

  factory TripNetProfitReportSourceModel.fromMap(Map<String, dynamic> map) {
    final validation = requiredMap(map['validation'], 'validation');
    return TripNetProfitReportSourceModel(
      metadata: ReportSourceMetadataModel.fromRoot(map),
      freightPrecisionLossCount: requiredInt(
        validation['freight_precision_loss_count'],
        'freight_precision_loss_count',
      ),
      negativeFreightCount: requiredInt(
        validation['negative_freight_count'],
        'negative_freight_count',
      ),
      expensePrecisionLossCount: requiredInt(
        validation['expense_precision_loss_count'],
        'expense_precision_loss_count',
      ),
      negativeExpenseCount: requiredInt(
        validation['negative_expense_count'],
        'negative_expense_count',
      ),
      trips: requiredMapList(
        map['trips'],
        'trips',
      ).map(TripNetProfitTripModel.fromMap).toList(growable: false),
      expenses: requiredMapList(
        map['expenses'],
        'expenses',
      ).map(TripNetProfitExpenseModel.fromMap).toList(growable: false),
    );
  }
}

final class TripNetProfitTripModel {
  final String tripId;
  final String? tripNumber;
  final DateTime operationalDate;
  final String status;
  final String customerId;
  final String customerName;
  final String? driverId;
  final String? driverName;
  final String? tractorHeadId;
  final String? tractorHeadPlateNumber;
  final String? trailerId;
  final String? trailerPlateNumber;
  final String loadingLocation;
  final String unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final int freightMinorUnits;

  const TripNetProfitTripModel({
    required this.tripId,
    required this.tripNumber,
    required this.operationalDate,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    required this.tractorHeadId,
    required this.tractorHeadPlateNumber,
    required this.trailerId,
    required this.trailerPlateNumber,
    required this.loadingLocation,
    required this.unloadingLocation,
    required this.loadingOrderNumber,
    required this.waybillNumber,
    required this.freightMinorUnits,
  });

  factory TripNetProfitTripModel.fromMap(Map<String, dynamic> map) {
    return TripNetProfitTripModel(
      tripId: requiredString(map['trip_id'], 'trip_id'),
      tripNumber: optionalString(map['trip_number'], 'trip_number'),
      operationalDate: requiredDate(
        map['operational_date'],
        'operational_date',
      ),
      status: requiredString(map['status'], 'status'),
      customerId: requiredString(map['customer_id'], 'customer_id'),
      customerName: requiredString(map['customer_name'], 'customer_name'),
      driverId: optionalString(map['driver_id'], 'driver_id'),
      driverName: optionalString(map['driver_name'], 'driver_name'),
      tractorHeadId: optionalString(map['tractor_head_id'], 'tractor_head_id'),
      tractorHeadPlateNumber: optionalString(
        map['tractor_head_plate_number'],
        'tractor_head_plate_number',
      ),
      trailerId: optionalString(map['trailer_id'], 'trailer_id'),
      trailerPlateNumber: optionalString(
        map['trailer_plate_number'],
        'trailer_plate_number',
      ),
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
      freightMinorUnits: requiredInt(
        map['freight_minor_units'],
        'freight_minor_units',
      ),
    );
  }
}

final class TripNetProfitExpenseModel {
  final String expenseId;
  final String tripId;
  final int amountMinorUnits;

  const TripNetProfitExpenseModel({
    required this.expenseId,
    required this.tripId,
    required this.amountMinorUnits,
  });

  factory TripNetProfitExpenseModel.fromMap(Map<String, dynamic> map) {
    return TripNetProfitExpenseModel(
      expenseId: requiredString(map['expense_id'], 'expense_id'),
      tripId: requiredString(map['trip_id'], 'trip_id'),
      amountMinorUnits: requiredInt(
        map['amount_minor_units'],
        'amount_minor_units',
      ),
    );
  }
}
