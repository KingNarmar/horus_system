import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_finance_trip_option.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_write_data.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_finance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/driver_finance_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('Driver Finance movement use cases', () {
    test('parses company currency and passes BusinessDate unchanged', () async {
      final repository = _FakeDriverFinanceRepository();
      final useCase = AddDriverAdvanceUseCase(repository);
      final movementDate = BusinessDate(year: 2026, month: 9, day: 8);

      final result = await useCase(
        AddDriverAdvanceParams(
          currentCompanyContext: _context,
          driverId: '  driver-1  ',
          amount: '125.50',
          movementDate: movementDate,
          notes: '  note  ',
        ),
      );

      expect(result, isA<Success<DriverFinancialMovement>>());
      expect(repository.lastWriteData?.movementDate, same(movementDate));
      expect(repository.lastWriteData?.driverId, 'driver-1');
      expect(repository.lastWriteData?.notes, 'note');
      expect(repository.lastWriteData?.amount.minorUnits, 12550);
      expect(repository.lastWriteData?.amount.currency.value, 'AED');
      expect(repository.lastWriteData?.currencyFractionDigits, 2);
      expect(repository.lastActorRole, CompanyRole.accountant.name);
    });

    test('rejects over-precision before repository write', () async {
      final repository = _FakeDriverFinanceRepository();
      final useCase = AddDriverAdvanceUseCase(repository);

      final result = await useCase(
        AddDriverAdvanceParams(
          currentCompanyContext: _context,
          driverId: 'driver-1',
          amount: '1.001',
          movementDate: BusinessDate(year: 2026, month: 9, day: 8),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverFinanceAmountPositive,
      );
      expect(repository.lastWriteData, isNull);
    });

    test('supports configured three-decimal currencies exactly', () async {
      final repository = _FakeDriverFinanceRepository();
      final useCase = AddDriverCashReturnUseCase(repository);

      final result = await useCase(
        AddDriverCashReturnParams(
          currentCompanyContext: _kwdContext,
          driverId: 'driver-1',
          amount: '12.345',
          movementDate: BusinessDate(year: 2026, month: 9, day: 8),
        ),
      );

      expect(result, isA<Success<DriverFinancialMovement>>());
      expect(repository.lastWriteData?.amount.minorUnits, 12345);
      expect(repository.lastWriteData?.amount.currency.value, 'KWD');
      expect(repository.lastWriteData?.currencyFractionDigits, 3);
    });

    test('passes company IANA timezone when loading trip options', () async {
      final repository = _FakeDriverFinanceRepository();
      final useCase = GetDriverTripOptionsUseCase(repository);

      final result = await useCase(
        const GetDriverTripOptionsParams(
          currentCompanyContext: _context,
          driverId: 'driver-1',
        ),
      );

      expect(result, isA<Success<List<DriverFinanceTripOption>>>());
      expect(repository.lastTripOptionsTimeZoneId, _timeZoneId);
    });
  });
}

const _timeZoneId = 'Africa/Tripoli';
const _context = CurrentCompanyContext(
  company: Company(
    id: 'company-1',
    name: 'Company',
    businessTimezone: _timeZoneId,
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  role: CompanyRole.accountant,
);
const _kwdContext = CurrentCompanyContext(
  company: Company(
    id: 'company-1',
    name: 'Company',
    businessTimezone: _timeZoneId,
    baseCurrencyCode: 'KWD',
    baseCurrencyFractionDigits: 3,
  ),
  role: CompanyRole.accountant,
);

class _FakeDriverFinanceRepository implements DriverFinanceRepository {
  DriverFinancialMovementWriteData? lastWriteData;
  String? lastActorRole;
  String? lastTripOptionsTimeZoneId;

  @override
  Future<Result<List<DriverFinancialMovement>>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) async {
    return const Success<List<DriverFinancialMovement>>([]);
  }

  @override
  Future<Result<List<DriverFinanceTripOption>>> getDriverTripOptions({
    required String companyId,
    required String driverId,
    required String timeZoneId,
  }) async {
    lastTripOptionsTimeZoneId = timeZoneId;
    return const Success<List<DriverFinanceTripOption>>([]);
  }

  @override
  Future<Result<DriverFinancialMovement>> addDriverMovement({
    required DriverFinancialMovementWriteData data,
    required String actorRole,
  }) async {
    lastWriteData = data;
    lastActorRole = actorRole;
    return Success(
      DriverFinancialMovement(
        id: 'movement-1',
        companyId: data.companyId,
        driverId: data.driverId,
        tripId: data.tripId,
        type: data.type,
        amount: data.amount.minorUnits.toDouble(),
        movementDate: data.movementDate,
        notes: data.notes,
      ),
    );
  }
}
