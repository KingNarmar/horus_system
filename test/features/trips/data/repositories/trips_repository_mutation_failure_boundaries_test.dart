import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

import 'trips_repository_test_support.dart';

void main() {
  group('TripsRepository atomic mutation failure boundaries', () {
    test('sanitizes create RPC failure without follow-up writes', () async {
      final events = <String>[];
      final remoteDataSource = FakeTripsRemoteDataSource(
        events: events,
        errors: const {
          TripDataOperation.create: PostgrestException(
            message: 'insert failed',
            code: '23503',
            details: 'sensitive details',
            hint: 'sensitive hint',
          ),
        },
      );
      final repository = createTripsRepository(remoteDataSource);

      final result = await repository.createTrip(
        data: testTripWriteData,
        financialConfiguration: testFinancialConfiguration,
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(events, ['create']);
    });

    test(
      'sanitizes save RPC failure without pre-read or follow-up writes',
      () async {
        final events = <String>[];
        final remoteDataSource = FakeTripsRemoteDataSource(
          currentModel: testOldTripModel,
          events: events,
          errors: const {
            TripDataOperation.save: PostgrestException(
              message: 'update failed',
              code: '42501',
            ),
          },
        );
        final repository = createTripsRepository(remoteDataSource);

        final result = await repository.saveTrip(
          id: testTripId,
          data: testTripWriteData,
          financialConfiguration: testFinancialConfiguration,
        );

        expect(result, isA<FailureResult<TripEntity>>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(events, ['save']);
        expect(remoteDataSource.lastGetByIdCompanyId, isNull);
      },
    );

    test(
      'sanitizes status RPC failure without client-side history or audit',
      () async {
        final events = <String>[];
        final remoteDataSource = FakeTripsRemoteDataSource(
          statusModel: testLoadedTripModel,
          events: events,
          errors: const {
            TripDataOperation.status: PostgrestException(
              message: 'status update failed',
              code: '42501',
            ),
          },
        );
        final repository = createTripsRepository(remoteDataSource);

        final result = await repository.updateTripStatus(
          companyId: testCompanyId,
          id: testTripId,
          newStatus: TripStatus.loaded,
          financialConfiguration: testFinancialConfiguration,
        );

        expect(result, isA<FailureResult<TripEntity>>());
        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
        expect(events, ['status']);
      },
    );
  });
}
