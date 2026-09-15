import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_form_lookups.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status_history.dart';
import 'package:horus_system/features/trips/domain/entities/trip_write_data.dart';
import 'package:horus_system/features/trips/domain/repositories/trips_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/trips_usecases.dart';
import 'package:horus_system/features/trips/domain/value_objects/quantity_tons.dart';
import 'package:test/test.dart';

void main() {
  const context = CurrentCompanyContext(
    company: Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
    ),
    role: CompanyRole.operations,
  );
  final configuration = CurrencyConfiguration.tryCreate(
    currencyCode: 'AED',
    fractionDigits: 2,
  )!;
  final currency = configuration.currency;

  group('CreateTripUseCase commercial snapshot', () {
    test('calculates final commercial amount once with half-up rounding', () async {
      final repository = _FakeTripsRepository();
      final useCase = CreateTripUseCase(repository);

      final result = await useCase(
        const CreateTripParams(
          currentCompanyContext: context,
          customerId: 'customer-1',
          routeId: 'route-1',
          quantityTonsInput: '10.125',
          agreedFreightRatePerTonInput: '100.55',
        ),
      );

      expect(result, isA<Success<TripEntity>>());
      final write = repository.lastWriteData!;
      expect(write.quantityTons, QuantityTons.tryParse('10.125'));
      expect(
        write.agreedFreightRatePerTon,
        Money(minorUnits: 10055, currency: currency),
      );
      expect(
        write.commercialAmount,
        Money(minorUnits: 101807, currency: currency),
      );
      expect(repository.lastFinancialConfiguration, configuration);
    });

    test('rejects incomplete quantity/rate terms', () async {
      final repository = _FakeTripsRepository();
      final useCase = CreateTripUseCase(repository);

      final result = await useCase(
        const CreateTripParams(
          currentCompanyContext: context,
          customerId: 'customer-1',
          routeId: 'route-1',
          quantityTonsInput: '10',
        ),
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripCommercialTermsIncomplete,
      );
      expect(repository.lastWriteData, isNull);
    });
  });

  group('SaveTripUseCase legacy commercial history', () {
    test('preserves legacy amount when quantity remains unchanged', () async {
      final repository = _FakeTripsRepository(
        currentTrip: TripEntity(
          id: 'trip-1',
          companyId: 'company-1',
          customerId: 'customer-1',
          routeId: 'route-1',
          status: TripStatus.delivered,
          quantityTons: QuantityTons.tryParse('20'),
          commercialAmount: Money(minorUnits: 500000, currency: currency),
        ),
      );
      final useCase = SaveTripUseCase(repository);

      final result = await useCase(
        const SaveTripParams(
          currentCompanyContext: context,
          id: 'trip-1',
          customerId: 'customer-1',
          routeId: 'route-1',
          quantityTonsInput: '20.000',
        ),
      );

      expect(result, isA<Success<TripEntity>>());
      expect(repository.lastWriteData?.agreedFreightRatePerTon, isNull);
      expect(
        repository.lastWriteData?.commercialAmount,
        Money(minorUnits: 500000, currency: currency),
      );
    });

    test('rejects changing legacy quantity without authoritative rate', () async {
      final repository = _FakeTripsRepository(
        currentTrip: TripEntity(
          id: 'trip-1',
          companyId: 'company-1',
          customerId: 'customer-1',
          routeId: 'route-1',
          status: TripStatus.delivered,
          quantityTons: QuantityTons.tryParse('20'),
          commercialAmount: Money(minorUnits: 500000, currency: currency),
        ),
      );
      final useCase = SaveTripUseCase(repository);

      final result = await useCase(
        const SaveTripParams(
          currentCompanyContext: context,
          id: 'trip-1',
          customerId: 'customer-1',
          routeId: 'route-1',
          quantityTonsInput: '21',
        ),
      );

      expect(result, isA<FailureResult<TripEntity>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripCommercialTermsIncomplete,
      );
      expect(repository.lastWriteData, isNull);
    });
  });
}

class _FakeTripsRepository implements TripsRepository {
  final TripEntity? currentTrip;
  TripWriteData? lastWriteData;
  CurrencyConfiguration? lastFinancialConfiguration;

  _FakeTripsRepository({this.currentTrip});

  TripEntity _entityFrom(TripWriteData data, {String id = 'trip-new'}) {
    return TripEntity(
      id: id,
      companyId: data.companyId,
      customerId: data.customerId,
      routeId: data.routeId,
      status: TripStatus.created,
      quantityTons: data.quantityTons,
      agreedFreightRatePerTon: data.agreedFreightRatePerTon,
      commercialAmount: data.commercialAmount,
    );
  }

  @override
  Future<Result<TripEntity>> createTrip({
    required TripWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    lastWriteData = data;
    lastFinancialConfiguration = financialConfiguration;
    return Success(_entityFrom(data));
  }

  @override
  Future<Result<TripEntity>> saveTrip({
    required String id,
    required TripWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    lastWriteData = data;
    lastFinancialConfiguration = financialConfiguration;
    return Success(_entityFrom(data, id: id));
  }

  @override
  Future<Result<TripEntity>> getTripDetails({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    final trip = currentTrip;
    if (trip == null) throw StateError('No current trip configured.');
    return Success(trip);
  }

  @override
  Future<Result<bool>> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) async => const Success(false);

  @override
  Future<Result<List<TripEntity>>> getTrips({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) async => const Success([]);

  @override
  Future<Result<TripFormLookups>> getTripFormLookups({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<TripEntity>> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
    String? notes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<TripStatusHistory>>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) async => const Success([]);
}
