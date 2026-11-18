import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';

/// Snapshot fields live on the invoice row, not in the mutable company profile.
final class InvoiceIssuerSnapshotModel {
  final String companyName;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? taxRegistrationNumber;
  final String? logoPath;
  final String source;
  final DateTime capturedAt;

  const InvoiceIssuerSnapshotModel({
    required this.companyName,
    this.businessType,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.taxRegistrationNumber,
    this.logoPath,
    required this.source,
    required this.capturedAt,
  });

  static InvoiceIssuerSnapshotModel? fromInvoiceMap(
    Map<String, dynamic> map,
  ) {
    final source = InvoiceDataParser.optionalString(
      map[InvoicesDbFields.issuerSnapshotSource],
    );
    if (source == null) return null;

    return InvoiceIssuerSnapshotModel(
      companyName: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.issuerCompanyName],
        InvoicesDbFields.issuerCompanyName,
      ),
      businessType: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.issuerBusinessType],
      ),
      phone: InvoiceDataParser.optionalString(map[InvoicesDbFields.issuerPhone]),
      email: InvoiceDataParser.optionalString(map[InvoicesDbFields.issuerEmail]),
      address: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.issuerAddress],
      ),
      city: InvoiceDataParser.optionalString(map[InvoicesDbFields.issuerCity]),
      country: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.issuerCountry],
      ),
      taxRegistrationNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.issuerTaxRegistrationNumber],
      ),
      logoPath: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.issuerLogoPath],
      ),
      source: source,
      capturedAt: InvoiceDataParser.requiredDateTime(
        map[InvoicesDbFields.issuerCapturedAt],
        InvoicesDbFields.issuerCapturedAt,
      ),
    );
  }
}
