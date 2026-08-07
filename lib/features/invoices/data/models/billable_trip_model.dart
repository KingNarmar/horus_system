import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';

final class BillableTripModel {
  final String id;
  final String companyId;
  final String customerId;
  final String status;
  final int freightMinorUnits;
  final String currencyCode;
  final bool isAlreadyInvoiced;
  final String? tripNumber;
  final String? customerName;
  final String? loadingLocation;
  final String? unloadingLocation;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final DateTime? serviceDate;
  final double? quantityTons;

  const BillableTripModel({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.status,
    required this.freightMinorUnits,
    required this.currencyCode,
    required this.isAlreadyInvoiced,
    this.tripNumber,
    this.customerName,
    this.loadingLocation,
    this.unloadingLocation,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.serviceDate,
    this.quantityTons,
  });

  factory BillableTripModel.fromMap(Map<String, dynamic> map) {
    final invoicedValue = map[InvoicesDbFields.isAlreadyInvoiced];
    if (invoicedValue is! bool) {
      throw FormatException(
        'Invalid invoice field: ${InvoicesDbFields.isAlreadyInvoiced}.',
      );
    }

    return BillableTripModel(
      id: InvoiceDataParser.requiredString(
        map[DbCommonFields.id],
        DbCommonFields.id,
      ),
      companyId: InvoiceDataParser.requiredString(
        map[DbCommonFields.companyId],
        DbCommonFields.companyId,
      ),
      customerId: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.customerId],
        InvoicesDbFields.customerId,
      ),
      status: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.status],
        InvoicesDbFields.status,
      ),
      freightMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.freightMinorUnits],
        InvoicesDbFields.freightMinorUnits,
      ),
      currencyCode: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.currencyCode],
        InvoicesDbFields.currencyCode,
      ),
      isAlreadyInvoiced: invoicedValue,
      tripNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.tripNumber],
      ),
      customerName: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerName],
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
    );
  }
}
