import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
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
import 'package:horus_system/features/trips/presentation/cubit/trip_freight_rate_cubit.dart';

void main() {
  test('saves rate via use case and exposes only typed success', () async {
    final repository = _FakeRepository();
    final cubit = TripFreightRateCubit(SetTripFreightRateUseCase(repository));

    await cubit.save(
      companyContext: _context(CompanyRole.accountant),
      trip: _trip,
      agreedFreightRatePerTonInput: '12.34',
    );

    expect(repository.calls, 1);
    expect(cubit.state, isA<TripFreightRateSaved>());
    expect((cubit.state as TripFreightRateSaved).trip.id, _trip.id);

    cubit.reset();
    expect(cubit.state, isA<TripFreightRateInitial>());
    await cubit.close();
  });

  test('surfaces finance denial without calling Data for Operations', () async {
    final repository = _FakeRepository();
    final cubit = TripFreightRateCubit(SetTripFreightRateUseCase(repository));

    await cubit.save(
      companyContext: _context(CompanyRole.operations),
      trip: _trip,
      agreedFreightRatePerTonInput: '12.34',
    );

    expect(repository.calls, 0);
    expect(cubit.state, isA<TripFreightRateFailure>());
    expect(
      (cubit.state as TripFreightRateFailure).failure.code,
      TripFailureCodes.financialTermsPermissionDenied,
    );
    await cubit.close();
  });

  test('rejects duplicate in-flight requests', () async {
    final repository = _FakeRepository(pending: Completer<Result<TripEntity>>());
    final cubit = TripFreightRateCubit(SetTripFreightRateUseCase(repository));

    final first = cubit.save(
      companyContext: _context(CompanyRole.accountant),
      trip: _trip,
      agreedFreightRatePerTonInput: '12.34',
    );
    final second = cubit.save(
      companyContext: _context(CompanyRole.accountant),
      trip: _trip,
      agreedFreightRatePerTonInput: '11.00',
    );

    expect(cubit.state, isA<TripFreightRateSaving>());
    expect(repository.calls, 1);
    repository.pending!.complete(const Success(_trip));
    await Future.wait([first, second]);
    expect(cubit.state, isA<TripFreightRateSaved>());
    await cubit.close();
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

final _trip = TripEntity(
  id: 'trip-1',
  companyId: 'company-1',
  tripNumber: TripNumber.tryParse('TRP-2026-000001')!,
  customerId: 'customer-1',
  routeId: 'route-1',
  status: TripStatus.created,
  quantityTons: QuantityTons.tryParse('10'),
  updatedAt: DateTime.utc(2026, 10, 18),
);

final class _FakeRepository implements TripFinancialTermsRepository {
  int calls = 0;
  final Completer<Result<TripEntity>>? pending;

  _FakeRepository({this.pending});

  @override
  Future<Result<TripEntity>> setFreightRate({
    required String companyId,
    required String tripId,
    required Money agreedFreightRatePerTon,
    required CurrencyConfiguration financialConfiguration,
    required DateTime expectedUpdatedAt,
  }) async {
    calls++;
    return pending?.future ?? Success(_trip);
  }
}
