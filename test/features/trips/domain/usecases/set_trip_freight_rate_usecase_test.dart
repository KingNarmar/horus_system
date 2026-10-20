import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/trips/domain/entities/trip_entity.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:horus_system/features/trips/domain/failures/trip_failure_codes.dart';
import 'package:horus_system/features/trips/domain/repositories/trip_financial_terms_repository.dart';
import 'package:horus_system/features/trips/domain/usecases/set_trip_freight_rate_usecase.dart';
import 'package:horus_system/features/trips/domain/value_objects/quantity_tons.dart';
import 'package:horus_system/features/trips/domain/value_objects/trip_number.dart';
import 'package:test/test.dart';

void main() {
  group('SetTripFreightRateUseCase', () {
    for (final role in [
      CompanyRole.owner,
      CompanyRole.admin,
      CompanyRole.accountant,
    ]) {
      test('${role.name} may change only Trip financial terms', () async {
        final repository = _FakeRepository();
        final trip = _trip();
        final result = await SetTripFreightRateUseCase(repository)(
          SetTripFreightRateParams(
            currentCompanyContext: _context(role),
            trip: trip,
            agreedFreightRatePerTonInput: '12.34',
          ),
        );

        expect(result, isA<Success<TripEntity>>());
        expect(repository.calls, 1);
        expect(repository.companyId, 'company-1');
        expect(repository.tripId, trip.id);
        expect(repository.rate?.minorUnits, 1234);
        expect(repository.expectedUpdatedAt, trip.updatedAt);
        expect(repository.configuration?.fractionDigits, 2);
      });
    }

    for (final role in [
      CompanyRole.operations,
      CompanyRole.viewer,
      CompanyRole.driver,
    ]) {
      test('denies ${role.name} before any financial write', () async {
        final repository = _FakeRepository();
        final result = await SetTripFreightRateUseCase(repository)(
          SetTripFreightRateParams(
            currentCompanyContext: _context(role),
            trip: _trip(),
            agreedFreightRatePerTonInput: '12.34',
          ),
        );
        expect(
          result.failureOrNull?.code,
          TripFailureCodes.financialTermsPermissionDenied,
        );
        expect(repository.calls, 0);
      });
    }

    test('rejects cross-company snapshot before repository access', () async {
      final repository = _FakeRepository();
      final result = await SetTripFreightRateUseCase(repository)(
        SetTripFreightRateParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          trip: _trip(companyId: 'other-company'),
          agreedFreightRatePerTonInput: '12.34',
        ),
      );
      expect(
        result.failureOrNull?.code,
        TripFailureCodes.financialTermsPermissionDenied,
      );
      expect(repository.calls, 0);
    });

    test('requires quantity and an optimistic concurrency snapshot', () async {
      final repository = _FakeRepository();
      final useCase = SetTripFreightRateUseCase(repository);
      final context = _context(CompanyRole.accountant);
      final withoutQuantity = await useCase(
        SetTripFreightRateParams(
          currentCompanyContext: context,
          trip: _trip(withQuantity: false),
          agreedFreightRatePerTonInput: '12.34',
        ),
      );
      final withoutUpdatedAt = await useCase(
        SetTripFreightRateParams(
          currentCompanyContext: context,
          trip: _trip(withUpdatedAt: false),
          agreedFreightRatePerTonInput: '12.34',
        ),
      );
      expect(
        withoutQuantity.failureOrNull?.code,
        TripFailureCodes.pricingRequiresQuantity,
      );
      expect(
        withoutUpdatedAt.failureOrNull?.code,
        TripFailureCodes.staleFinancialSnapshot,
      );
      expect(repository.calls, 0);
    });

    test('validates currency precision before repository access', () async {
      final repository = _FakeRepository();
      final result = await SetTripFreightRateUseCase(repository)(
        SetTripFreightRateParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          trip: _trip(),
          agreedFreightRatePerTonInput: '12.345',
        ),
      );
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationTripFreightRateInvalid,
      );
      expect(repository.calls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) => CurrentCompanyContext(
  company: const Company(
    id: 'company-1',
    name: 'Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  role: role,
);

TripEntity _trip({
  String companyId = 'company-1',
  bool withQuantity = true,
  bool withUpdatedAt = true,
}) => TripEntity(
  id: 'trip-1',
  companyId: companyId,
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.created,
  quantityTons: withQuantity ? QuantityTons.tryParse('10.125') : null,
  updatedAt: withUpdatedAt ? DateTime.utc(2026, 10, 18) : null,
);

final class _FakeRepository implements TripFinancialTermsRepository {
  int calls = 0;
  String? companyId;
  String? tripId;
  Money? rate;
  CurrencyConfiguration? configuration;
  DateTime? expectedUpdatedAt;

  @override
  Future<Result<TripEntity>> setFreightRate({
    required String companyId,
    required String tripId,
    required Money agreedFreightRatePerTon,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    calls += 1;
    this.companyId = companyId;
    this.tripId = tripId;
    rate = agreedFreightRatePerTon;
    configuration = financialConfiguration;
    this.expectedUpdatedAt = expectedUpdatedAt;
    return Success(_trip());
  }
}
