import 'package:horus_system/features/trips/data/models/trip_model.dart';
import 'package:horus_system/features/trips/data/models/trip_status_history_model.dart';
import 'package:test/test.dart';

void main() {
  group('Trip timestamp persistence', () {
    test('normalizes operational and system timestamps to UTC', () {
      final model = TripModel.fromMap({
        'id': 'trip-1',
        'company_id': 'company-1',
        'customer_id': 'customer-1',
        'route_id': 'route-1',
        'status': 'created',
        'scheduled_loading_at': '2026-09-07T00:30:00+04:00',
        'created_at': '2026-09-07T01:00:00+04:00',
      });

      expect(
        model.scheduledLoadingAt,
        DateTime.utc(2026, 9, 6, 20, 30),
      );
      expect(model.scheduledLoadingAt?.isUtc, isTrue);
      expect(model.createdAt, DateTime.utc(2026, 9, 6, 21));
      expect(model.createdAt?.isUtc, isTrue);
    });

    test('rejects timezone-less operational timestamps', () {
      expect(
        () => TripModel.fromMap({
          'id': 'trip-1',
          'company_id': 'company-1',
          'customer_id': 'customer-1',
          'route_id': 'route-1',
          'scheduled_loading_at': '2026-09-07T00:30:00',
        }),
        throwsFormatException,
      );
    });

    test('status history requires a real persisted instant', () {
      expect(
        () => TripStatusHistoryModel.fromMap({
          'id': 'history-1',
          'company_id': 'company-1',
          'trip_id': 'trip-1',
          'new_status': 'assigned',
          'changed_at': null,
        }),
        throwsFormatException,
      );
    });
  });
}
