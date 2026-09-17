import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_money_balance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_canonical_driver_money_balance_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetCanonicalDriverMoneyBalanceUseCase', () {
    test('forwards typed company currency and exact date boundaries', () async {
      final repository = _FakeDriverMoneyBalanceRepository();
      final useCase = GetCanonicalDriverMoneyBalanceUseCase(repository);
      final beforeExclusive = BusinessDate(year: 2026, month: 9, day: 17);
      final checkpointBeforeExclusive = BusinessDate(
        year: 2026,
        month: 9,
        day: 1,
      );

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(
            role: CompanyRole.accountant,
            currencyCode: 'AED',
            fractionDigits: 2,
          ),
          driverId: '  driver-1  ',
          beforeExclusive: beforeExclusive,
          checkpointBeforeExclusive: checkpointBeforeExclusive,
        ),
      );

      expect(result, isA<Success<DriverMoneyBalance>>());
      expect(repository.moneyBalanceCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastDriverId, 'driver-1');
      expect(repository.lastCurrency?.value, 'AED');
      expect(repository.lastFractionDigits, 2);
      expect(repository.lastBeforeExclusive, beforeExclusive);
      expect(
        repository.lastCheckpointBeforeExclusive,
        checkpointBeforeExclusive,
      );
    });

    test('requires configured company financial settings', () async {
      final repository = _FakeDriverMoneyBalanceRepository();
      final useCase = GetCanonicalDriverMoneyBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(role: CompanyRole.owner),
          driverId: 'driver-1',
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 17),
        ),
      );

      expect(result, isA<FailureResult<DriverMoneyBalance>>());
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
      );
      expect(repository.moneyBalanceCalls, 0);
    });

    test('rejects invalid company currency code', () async {
      final repository = _FakeDriverMoneyBalanceRepository();
      final useCase = GetCanonicalDriverMoneyBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(
            role: CompanyRole.owner,
            currencyCode: 'AE',
            fractionDigits: 2,
          ),
          driverId: 'driver-1',
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 17),
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyInvalid,
      );
      expect(repository.moneyBalanceCalls, 0);
    });

    test('rejects invalid company fraction digits', () async {
      final repository = _FakeDriverMoneyBalanceRepository();
      final useCase = GetCanonicalDriverMoneyBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(
            role: CompanyRole.owner,
            currencyCode: 'AED',
            fractionDigits: 5,
          ),
          driverId: 'driver-1',
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 17),
        ),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
      );
      expect(repository.moneyBalanceCalls, 0);
    });

    test('blocks driver role before repository access', () async {
      final repository = _FakeDriverMoneyBalanceRepository();
      final useCase = GetCanonicalDriverMoneyBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(
            role: CompanyRole.driver,
            currencyCode: 'AED',
            fractionDigits: 2,
          ),
          driverId: 'driver-1',
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 17),
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionDriverFinanceView,
      );
      expect(repository.moneyBalanceCalls, 0);
    });

    test('requires driver id before repository access', () async {
      final repository = _FakeDriverMoneyBalanceRepository();
      final useCase = GetCanonicalDriverMoneyBalanceUseCase(repository);

      final result = await useCase(
        GetCanonicalDriverBalanceParams(
          currentCompanyContext: _context(
            role: CompanyRole.viewer,
            currencyCode: 'AED',
            fractionDigits: 2,
          ),
          driverId: '   ',
          beforeExclusive: BusinessDate(year: 2026, month: 9, day: 17),
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverIdRequired,
      );
      expect(repository.moneyBalanceCalls, 0);
    });
  });
}

CurrentCompanyContext _context({
  required CompanyRole role,
  String? currencyCode,
  int? fractionDigits,
}) {
  return CurrentCompanyContext(
    company: Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: currencyCode,
      baseCurrencyFractionDigits: fractionDigits,
    ),
    role: role,
  );
}

class _FakeDriverMoneyBalanceRepository
    implements DriverMoneyBalanceRepository {
  int moneyBalanceCalls = 0;
  String? lastCompanyId;
  String? lastDriverId;
  CurrencyCode? lastCurrency;
  int? lastFractionDigits;
  BusinessDate? lastBeforeExclusive;
  BusinessDate? lastCheckpointBeforeExclusive;

  @override
  Future<Result<DriverMoneyBalance>> getCanonicalDriverMoneyBalance({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    moneyBalanceCalls++;
    lastCompanyId = companyId;
    lastDriverId = driverId;
    lastCurrency = currency;
    lastFractionDigits = currencyFractionDigits;
    lastBeforeExclusive = beforeExclusive;
    lastCheckpointBeforeExclusive = checkpointBeforeExclusive;

    final zero = Money(minorUnits: 0, currency: currency);
    return Success(
      DriverMoneyBalance(
        companyId: companyId,
        driverId: driverId,
        currency: currency,
        currencyFractionDigits: currencyFractionDigits,
        totalAdvances: zero,
        totalDriverCharges: zero,
        totalTripExpenseCredits: zero,
        totalCashReturns: zero,
      ),
    );
  }
}
