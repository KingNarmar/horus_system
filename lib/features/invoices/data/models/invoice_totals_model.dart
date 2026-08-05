import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';

final class InvoiceTotalsModel {
  final int subtotalMinorUnits;
  final int discountMinorUnits;
  final int taxableMinorUnits;
  final int taxRateBasisPoints;
  final int taxMinorUnits;
  final int totalMinorUnits;
  final String currencyCode;

  const InvoiceTotalsModel({
    required this.subtotalMinorUnits,
    required this.discountMinorUnits,
    required this.taxableMinorUnits,
    required this.taxRateBasisPoints,
    required this.taxMinorUnits,
    required this.totalMinorUnits,
    required this.currencyCode,
  });

  factory InvoiceTotalsModel.fromMap(Map<String, dynamic> map) {
    return InvoiceTotalsModel(
      subtotalMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.subtotalMinorUnits],
        InvoicesDbFields.subtotalMinorUnits,
      ),
      discountMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.discountMinorUnits],
        InvoicesDbFields.discountMinorUnits,
      ),
      taxableMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.taxableMinorUnits],
        InvoicesDbFields.taxableMinorUnits,
      ),
      taxRateBasisPoints: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.taxRateBasisPoints],
        InvoicesDbFields.taxRateBasisPoints,
      ),
      taxMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.taxMinorUnits],
        InvoicesDbFields.taxMinorUnits,
      ),
      totalMinorUnits: InvoiceDataParser.requiredInt(
        map[InvoicesDbFields.totalMinorUnits],
        InvoicesDbFields.totalMinorUnits,
      ),
      currencyCode: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.currencyCode],
        InvoicesDbFields.currencyCode,
      ),
    );
  }
}
