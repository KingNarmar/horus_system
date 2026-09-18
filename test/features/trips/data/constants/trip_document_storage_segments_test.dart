import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/trips/data/constants/trip_document_storage_segments.dart';
import 'package:horus_system/features/trips/domain/entities/trip_document_kind.dart';

void main() {
  test('maps business document kinds to PC-03 safe storage segments', () {
    expect(
      TripDocumentStorageSegments.forKind(TripDocumentKind.loadingOrder),
      'loading-order',
    );
    expect(
      TripDocumentStorageSegments.forKind(TripDocumentKind.waybill),
      'waybill',
    );
    expect(
      TripDocumentStorageSegments.forKind(TripDocumentKind.proofOfDelivery),
      'proof-of-delivery',
    );
    expect(
      TripDocumentStorageSegments.forKind(TripDocumentKind.other),
      'other',
    );
  });
}
