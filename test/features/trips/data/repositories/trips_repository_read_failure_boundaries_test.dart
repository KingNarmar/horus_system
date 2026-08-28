import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

import 'trips_repository_test_support.dart';

void main() {
  group('TripsRepository read failure boundaries', () {
    test('forwards company scope for read operations', () async {
      final remoteDataSource = FakeTripsRemoteDataSource();
      final repository = createTripsRepository(remoteDataSource);

      final listResult = await repository.getTrips(companyId: testCompanyId);
      final detailsResult = await repository.getTripDetails(
        companyId: testCompanyId,
        id: testTripId,
      );
      final lookupsResult = await repository.getTripFormLookups(
        companyId: testCompanyId,
      );
      final historyResult = await repository.getTripStatusHistory(
        companyId: testCompanyId,
        tripId: testTripId,
      );
      final openTripResult = await repository.hasOpenTripForVehicle(
        companyId: testCompanyId,
        tractorHeadId: 'tractor-1',
        trailerId: 'trailer-1',
        excludingTripId: testTripId,
      );

      expect(listResult, isA<Success<List<TripEntity>>>());
      expect(detailsResult, isA<Success<TripEntity>>());
      expect(lookupsResult, isA<Success<TripFormLookups>>());
      expect(historyResult, isA<Success>());
      expect(openTripResult, isA<Success<bool>>());
      expect(remoteDataSource.lastListCompanyId, testCompanyId);
      expect(remoteDataSource.lastGetByIdCompanyId, testCompanyId);
      expect(remoteDataSource.lastGetByIdId, testTripId);
      expect(remoteDataSource.lastLookupsCompanyId, testCompanyId);
      expect(remoteDataSource.lastHistoryListCompanyId, testCompanyId);
      expect(remoteDataSource.lastHistoryListTripId, testTripId);
      expect(remoteDataSource.lastOpenTripCompanyId, testCompanyId);
      expect(remoteDataSource.lastOpenTripTractorHeadId, 'tractor-1');
      expect(remoteDataSource.lastOpenTripTrailerId, 'trailer-1');
      expect(remoteDataSource.lastOpenTripExcludingTripId, testTripId);
    });

    test(
      'sanitizes Postgrest read failures and preserves company forwarding',
      () async {
        final remoteDataSource = FakeTripsRemoteDataSource(
          errors: const {
            TripDataOperation.list: PostgrestException(
              message: 'permission denied',
              code: '42501',
              details: 'sensitive details',
              hint: 'sensitive hint',
            ),
          },
        );
        final repository = createTripsRepository(remoteDataSource);

        final result = await repository.getTrips(companyId: testCompanyId);

        expect(result, isA<FailureResult<List<TripEntity>>>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, testCompanyId);
      },
    );

    test(
      'sanitizes model-to-entity mapping failures inside repository guard',
      () async {
        final remoteDataSource = FakeTripsRemoteDataSource(
          listModels: const [ThrowingTripModel()],
        );
        final repository = createTripsRepository(remoteDataSource);

        final result = await repository.getTrips(companyId: testCompanyId);

        expect(result, isA<FailureResult<List<TripEntity>>>());
        expect(result.failureOrNull, isA<UnexpectedFailure>());
        expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
        expect(result.failureOrNull?.message, isNull);
        expect(remoteDataSource.lastListCompanyId, testCompanyId);
      },
    );
  });
}
