import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/invoices_db_fields.dart';
import '../utils/invoice_data_parser.dart';

final class InvoiceCustomerSnapshotModel {
  final String companyId;
  final String customerId;
  final String name;
  final String? taxRegistrationNumber;
  final String? address;
  final String? city;
  final String? country;

  const InvoiceCustomerSnapshotModel({
    required this.companyId,
    required this.customerId,
    required this.name,
    this.taxRegistrationNumber,
    this.address,
    this.city,
    this.country,
  });

  factory InvoiceCustomerSnapshotModel.fromInvoiceMap(
    Map<String, dynamic> map,
  ) {
    return InvoiceCustomerSnapshotModel(
      companyId: InvoiceDataParser.requiredString(
        map[DbCommonFields.companyId],
        DbCommonFields.companyId,
      ),
      customerId: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.customerId],
        InvoicesDbFields.customerId,
      ),
      name: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.customerName],
        InvoicesDbFields.customerName,
      ),
      taxRegistrationNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerTaxRegistrationNumber],
      ),
      address: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerAddress],
      ),
      city: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerCity],
      ),
      country: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerCountry],
      ),
    );
  }

  factory InvoiceCustomerSnapshotModel.fromContextMap(
    Map<String, dynamic> map, {
    required String companyId,
  }) {
    return InvoiceCustomerSnapshotModel(
      companyId: companyId,
      customerId: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.customerId],
        InvoicesDbFields.customerId,
      ),
      name: InvoiceDataParser.requiredString(
        map[InvoicesDbFields.customerName],
        InvoicesDbFields.customerName,
      ),
      taxRegistrationNumber: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerTaxRegistrationNumber],
      ),
      address: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerAddress],
      ),
      city: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerCity],
      ),
      country: InvoiceDataParser.optionalString(
        map[InvoicesDbFields.customerCountry],
      ),
    );
  }
}
