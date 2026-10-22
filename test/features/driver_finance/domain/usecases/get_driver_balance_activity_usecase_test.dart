import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_balance_activity_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_driver_balance_activity_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('GetDriverBalanceActivityUseCase', () {
    test(
      'scopes the read to the company and exact currency configuration',
      () async {
        final repository = _FakeActivityRepository();
        final useCase = GetDriverBalanceActivityUseCase(repository);
        final before = BusinessDate(year: 2026, month: 10, day: 23);
        final checkpointBefore = BusinessDate(year: 2026, month: 9, day: 1);

        final result = await useCase(
          GetDriverBalanceActivityParams(
            currentCompanyContext: _context(CompanyRole.accountant),
            driverId: '  driver-1  ',
            beforeExclusive: before,
            checkpointBeforeExclusive: checkpointBefore,
          ),
        );

        expect(result, isA<Success<DriverBalanceActivity>>());
        expect(repository.calls, 1);
        expect(repository.companyId, 'company-1');
        expect(repository.driverId, 'driver-1');
        expect(repository.currency?.value, 'AED');
        expect(repository.fractionDigits, 2);
        expect(repository.beforeExclusive, before);
        expect(repository.checkpointBeforeExclusive, checkpointBefore);
      },
    );

    test('rejects unauthorized roles before any financial read', () async {
      for (final role in [
        CompanyRole.operations,
        CompanyRole.viewer,
        CompanyRole.driver,
      ]) {
        final repository = _FakeActivityRepository();
        final result = await GetDriverBalanceActivityUseCase(repository)(
          GetDriverBalanceActivityParams(
            currentCompanyContext: _context(role),
            driverId: 'driver-1',
            beforeExclusive: BusinessDate(year: 2026, month: 10, day: 23),
          ),
        );

        expect(
          result.failureOrNull?.code,
          FailureCodes.permissionDriverFinanceView,
        );
        expect(repository.calls, 0);
      }
    });

    test('requires driver identity before data access', () async {
      final repository = _FakeActivityRepository();
      final result = await GetDriverBalanceActivityUseCase(repository)(
        GetDriverBalanceActivityParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: '  ',
          beforeExclusive: BusinessDate(year: 2026, month: 10, day: 23),
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverIdRequired,
      );
      expect(repository.calls, 0);
    });

    test('rejects missing or invalid company currency configuration', () async {
      final repository = _FakeActivityRepository();
      final useCase = GetDriverBalanceActivityUseCase(repository);
      final before = BusinessDate(year: 2026, month: 10, day: 23);

      final missing = await useCase(
        GetDriverBalanceActivityParams(
          currentCompanyContext: _context(
            CompanyRole.owner,
            currencyCode: null,
          ),
          driverId: 'driver-1',
          beforeExclusive: before,
        ),
      );
      expect(
        missing.failureOrNull?.code,
        CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
      );

      final wrongDigits = await useCase(
        GetDriverBalanceActivityParams(
          currentCompanyContext: _context(CompanyRole.owner, fractionDigits: 5),
          driverId: 'driver-1',
          beforeExclusive: before,
        ),
      );
      expect(
        wrongDigits.failureOrNull?.code,
        CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
      );
      expect(repository.calls, 0);
    });
  });

  group('GetCurrentDriverBalanceActivityUseCase', () {
    test(
      'uses company business date and exclusive next-day boundary',
      () async {
        final repository = _FakeActivityRepository();
        final provider = _FakeDateProvider(
          Success(BusinessDate(year: 2026, month: 10, day: 22)),
        );
        final useCase = GetCurrentDriverBalanceActivityUseCase(
          getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
            provider,
          ),
          getDriverBalanceActivityUseCase: GetDriverBalanceActivityUseCase(
            repository,
          ),
        );

        final result = await useCase(
          GetCurrentDriverBalanceActivityParams(
            currentCompanyContext: _context(CompanyRole.owner),
            driverId: 'driver-1',
          ),
        );

        expect(result, isA<Success<DriverBalanceActivity>>());
        expect(provider.calls, 1);
        expect(provider.lastCompanyId, 'company-1');
        expect(
          repository.beforeExclusive,
          BusinessDate(year: 2026, month: 10, day: 23),
        );
      },
    );

    test('does not read sources after trusted date lookup fails', () async {
      const failure = ServerFailure(code: FailureCodes.serverError);
      final provider = _FakeDateProvider(
        const FailureResult<BusinessDate>(failure),
      );
      final repository = _FakeActivityRepository();
      final useCase = GetCurrentDriverBalanceActivityUseCase(
        getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(provider),
        getDriverBalanceActivityUseCase: GetDriverBalanceActivityUseCase(
          repository,
        ),
      );

      final result = await useCase(
        GetCurrentDriverBalanceActivityParams(
          currentCompanyContext: _context(CompanyRole.admin),
          driverId: 'driver-1',
        ),
      );

      expect(result.failureOrNull, same(failure));
      expect(repository.calls, 0);
    });
  });
}

CurrentCompanyContext _context(
  CompanyRole role, {
  String? currencyCode = 'AED',
  int? fractionDigits = 2,
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

final class _FakeActivityRepository implements DriverBalanceActivityRepository {
  int calls = 0;
  String? companyId;
  String? driverId;
  CurrencyCode? currency;
  int? fractionDigits;
  BusinessDate? beforeExclusive;
  BusinessDate? checkpointBeforeExclusive;

  @override
  Future<Result<DriverBalanceActivity>> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    calls++;
    this.companyId = companyId;
    this.driverId = driverId;
    this.currency = currency;
    fractionDigits = currencyFractionDigits;
    this.beforeExclusive = beforeExclusive;
    this.checkpointBeforeExclusive = checkpointBeforeExclusive;

    final zero = Money(minorUnits: 0, currency: currency);
    return Success(
      DriverBalanceActivity(
        canonicalBalance: DriverMoneyBalance(
          companyId: companyId,
          driverId: driverId,
          currency: currency,
          currencyFractionDigits: currencyFractionDigits,
          totalAdvances: zero,
          totalDriverCharges: zero,
          totalTripExpenseCredits: zero,
          totalCashReturns: zero,
        ),
        entries: const [],
      ),
    );
  }
}

final class _FakeDateProvider implements CompanyBusinessDateProvider {
  final Result<BusinessDate> result;
  int calls = 0;
  String? lastCompanyId;

  _FakeDateProvider(this.result);

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    calls++;
    lastCompanyId = companyId;
    return result;
  }
}
