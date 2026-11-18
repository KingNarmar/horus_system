/// Indicates whether a persisted issuer identity was captured at issuance or
/// reconstructed as a current-data baseline for a legacy invoice.
enum InvoiceIssuerSnapshotSource {
  issuance('issuance'),
  legacyBaseline('legacy_baseline');

  final String value;

  const InvoiceIssuerSnapshotSource(this.value);

  static InvoiceIssuerSnapshotSource? tryFromValue(String value) {
    for (final source in values) {
      if (source.value == value) return source;
    }
    return null;
  }
}

/// Immutable business-document identity, independent of the current company
/// profile. Storage object keys are private identifiers, never public URLs.
final class InvoiceIssuerSnapshot {
  final String companyName;
  final String? businessType;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? country;
  final String? taxRegistrationNumber;
  final String? logoPath;
  final InvoiceIssuerSnapshotSource source;
  final DateTime capturedAt;

  const InvoiceIssuerSnapshot({
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
}
