import 'dart:typed_data';

import 'invoice.dart';
import 'invoice_issuer_snapshot.dart';

/// A current company identity only for drafts, or a persisted issuer identity
/// for all other invoice states. Null provenance means a live draft preview.
final class InvoicePdfIssuerIdentity {
  final String name;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? taxRegistrationNumber;
  final String? logoPath;
  final InvoiceIssuerSnapshotSource? snapshotSource;

  const InvoicePdfIssuerIdentity({
    required this.name,
    this.businessType,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.country,
    this.taxRegistrationNumber,
    this.logoPath,
    this.snapshotSource,
  });
}

/// Authorized, immutable-by-reference input for the PDF renderer.
/// Financial totals come from Invoice, never from UI or PDF calculations.
final class InvoicePdfDocument {
  final Invoice invoice;
  final InvoicePdfIssuerIdentity issuer;
  final Uint8List? logoBytes;
  final int currencyFractionDigits;

  const InvoicePdfDocument({
    required this.invoice,
    required this.issuer,
    this.logoBytes,
    required this.currencyFractionDigits,
  });
}
