import '../../domain/entities/invoice_issuer_snapshot.dart';
import '../models/invoice_issuer_snapshot_model.dart';

extension InvoiceIssuerSnapshotModelMapper on InvoiceIssuerSnapshotModel {
  InvoiceIssuerSnapshot toEntity() {
    final parsedSource = InvoiceIssuerSnapshotSource.tryFromValue(source);
    if (parsedSource == null) {
      throw FormatException('Invalid persisted invoice issuer snapshot source.');
    }
    return InvoiceIssuerSnapshot(
      companyName: companyName,
      businessType: businessType,
      phone: phone,
      email: email,
      address: address,
      city: city,
      country: country,
      taxRegistrationNumber: taxRegistrationNumber,
      logoPath: logoPath,
      source: parsedSource,
      capturedAt: capturedAt,
    );
  }
}
