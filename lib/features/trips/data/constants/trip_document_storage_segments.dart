import '../../domain/entities/trip_document_kind.dart';

abstract final class TripDocumentStorageSegments {
  static String forKind(TripDocumentKind kind) {
    return switch (kind) {
      TripDocumentKind.loadingOrder => 'loading-order',
      TripDocumentKind.waybill => 'waybill',
      TripDocumentKind.proofOfDelivery => 'proof-of-delivery',
      TripDocumentKind.other => 'other',
    };
  }
}
