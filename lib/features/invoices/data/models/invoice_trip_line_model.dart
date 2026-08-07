import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';

final class InvoiceTripLineModel {
  final int linePosition;
  final String tripId;
  final String? tripNumber;
  final String? loadingLocation;
  final String? unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final DateTime? serviceDate;
  final double? quantityTons;
  final int amountMinorUnits;
  final String currencyCode;

  const InvoiceTripLineModel({
    required this.linePosition,
    required this.tripId,
    this.tripNumber,
    this.loadingLocation,
    this.unloadingLocation,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.serviceDate,
    this.quantityTons,
    required this.amountMinorUnits,
    required this.currencyCode,
  });

  factory InvoiceTripLineModel.fromMap(Map<String, dynamic> map) {
    return InvoiceTripLineModel(
      linePosition: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.linePosition],
        InvoicesDbFields.linePosition,
      ),
      tripId: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.tripId],
        InvoicesDbFields.tripId,
      ),
      tripNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.tripNumber],
      ),
      loadingLocation: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.loadingLocation],
      ),
      unloadingLocation: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.unloadingLocation],
      ),
      loadingOrderNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.loadingOrderNumber],
      ),
      waybillNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.waybillNumber],
      ),
      serviceDate: InvoiceDataParser.optionalDate(
        map[InvoicesDbFields.serviceDate],
        InvoicesDbFields.serviceDate,
      ),
      quantityTons: InvoiceDataParser.optionalDouble(
        map[InvoicesDbFields.quantityTons],
        InvoicesDbFields.quantityTons,
      ),
      amountMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.amountMinorUnits],
        InvoicesDbFields.amountMinorUnits,
      ),
      currencyCode: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.currencyCode],
        InvoicesDbFields.currencyCode,
      ),
    );
  }
}
