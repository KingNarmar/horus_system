enum TripDocumentKind {
  loadingOrder,
  waybill,
  proofOfDelivery,
  other,
}

extension TripDocumentKindX on TripDocumentKind {
  String get value {
    return switch (this) {
      TripDocumentKind.loadingOrder => 'loading_order',
      TripDocumentKind.waybill => 'waybill',
      TripDocumentKind.proofOfDelivery => 'proof_of_delivery',
      TripDocumentKind.other => 'other',
    };
  }

  static TripDocumentKind fromValue(String value) {
    return TripDocumentKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => TripDocumentKind.other,
    );
  }
}
