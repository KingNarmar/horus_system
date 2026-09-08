import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/usecases/trip_business_time_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('ResolveTripBusinessLocalTimestampsUseCase', () {
    test('uses the current company IANA timezone for conversion', () async {
      final converter = _FakeBusinessTimeZoneConverter();
      final useCase = ResolveTripBusinessLocalTimestampsUseCase(converter);
      final local = _local(2026, 9, 7, 0, 30);

      final result = await useCase(
        ResolveTripBusinessLocalTimestampsParams(
          currentCompanyContext: _context('Asia/Dubai'),
          scheduledLoadingAt: local,
        ),
      );

      expect(result, isA<Success>());
      expect(converter.lastTimeZoneId, 'Asia/Dubai');
      expect(converter.lastLocalDateTime, local);
      expect(
        result.dataOrNull?.scheduledLoadingAt,
        DateTime.utc(2026, 9, 6, 20, 30),
      );
    });

    test('fails typed when company timezone is not configured', () async {
      final converter = _FakeBusinessTimeZoneConverter();
      final useCase = ResolveTripBusinessLocalTimestampsUseCase(converter);

      final result = await useCase(
        ResolveTripBusinessLocalTimestampsParams(
          currentCompanyContext: _context(null),
          scheduledLoadingAt: _local(2026, 9, 7, 0, 30),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
      expect(converter.toUtcCalls, 0);
    });
  });

  group('GetTripBusinessLocalTimestampsUseCase', () {
    test('renders persisted instants in the current company timezone', () async {
      final converter = _FakeBusinessTimeZoneConverter();
      final useCase = GetTripBusinessLocalTimestampsUseCase(converter);
      final trip = TripEntity(
        id: 'trip-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        routeId: 'route-1',
        status: TripStatus.created,
        scheduledLoadingAt: DateTime.utc(2026, 9, 6, 20, 30),
      );

      final result = await useCase(
        GetTripBusinessLocalTimestampsParams(
          currentCompanyContext: _context('Asia/Dubai'),
          trip: trip,
        ),
      );

      expect(result, isA<Success>());
      expect(converter.lastTimeZoneId, 'Asia/Dubai');
      expect(
        result.dataOrNull?.scheduledLoadingAt,
        _local(2026, 9, 7, 0, 30),
      );
    });
  });
}

CurrentCompanyContext _context(String? timeZoneId) {
  return CurrentCompanyContext(
    company: Company(
      id: 'company-1',
      name: 'Company',
      businessTimezone: timeZoneId,
    ),
    role: CompanyRole.operations,
  );
}

BusinessLocalDateTime _local(
  int year,
  int month,
  int day,
  int hour,
  int minute,
) {
  return BusinessLocalDateTime(
    year: year,
    month: month,
    day: day,
    hour: hour,
    minute: minute,
  );
}

final class _FakeBusinessTimeZoneConverter
    implements BusinessTimeZoneConverter {
  int toUtcCalls = 0;
  String? lastTimeZoneId;
  BusinessLocalDateTime? lastLocalDateTime;

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) {
    toUtcCalls += 1;
    lastTimeZoneId = timeZoneId;
    lastLocalDateTime = localDateTime;
    return Success(DateTime.utc(2026, 9, 6, 20, 30));
  }

  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) {
    lastTimeZoneId = timeZoneId;
    return Success(_local(2026, 9, 7, 0, 30));
  }
}
