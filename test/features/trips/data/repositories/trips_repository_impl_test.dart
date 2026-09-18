import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

import 'trips_repository_test_support.dart';

void main() {
  group('TripsRepositoryImpl atomic mutation boundary', () {
    test('create delegates to one atomic datasource mutation', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(events: events);
      final repository = createTripsRepository(remoteDataSource);

      final result = await repository.createTrip(
        data: testTripWriteData,
        financialConfiguration: testFinancialConfiguration,
      );

      expect(result, isA<Success<TripEntity>>());
      expect(events, ['create']);
      expect(
        remoteDataSource.lastCreateFinancialConfiguration,
        testFinancialConfiguration,
      );
    });

    test('save delegates to one atomic datasource mutation', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        currentModel: testOldTripModel,
        events: events,
      );
      final repository = createTripsRepository(remoteDataSource);

      final result = await repository.saveTrip(
        id: testTripId,
        data: testTripWriteData,
        financialConfiguration: testFinancialConfiguration,
      );

      expect(result, isA<Success<TripEntity>>());
      expect(events, ['save']);
      expect(
        remoteDataSource.lastSaveFinancialConfiguration,
        testFinancialConfiguration,
      );
    });

    test(
      'status update delegates history and audit to atomic datasource',
      () async {
        final events = <String>[];
        final remoteDataSource = FakeTripsRemoteDataSource(
          statusModel: testLoadedTripModel,
          events: events,
        );
        final repository = createTripsRepository(remoteDataSource);

        final result = await repository.updateTripStatus(
          companyId: testCompanyId,
          id: testTripId,
          newStatus: TripStatus.loaded,
          financialConfiguration: testFinancialConfiguration,
          notes: 'Loaded at yard',
        );

        expect(result, isA<Success<TripEntity>>());
        expect(events, ['status']);
        expect(remoteDataSource.lastStatusNotes, 'Loaded at yard');
      },
    );
  });
}
