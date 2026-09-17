import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/failures/driver_compensation_failure_codes.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('ResolveDriverCompensationForPeriodUseCase', () {
    test('resolves one revision covering the complete period', () async {
      final repository = _FakeRepository([
        _revision(
          id: 'rev-1',
          from: BusinessDate(year: 2026, month: 1, day: 1),
          to: null,
        ),
      ]);
      final useCase = ResolveDriverCompensationForPeriodUseCase(repository);

      final result = await useCase(
        ResolveDriverCompensationForPeriodParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: 'driver-1',
          periodStart: BusinessDate(year: 2026, month: 9, day: 1),
          periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
        ),
      );

      expect(result.dataOrNull?.id, 'rev-1');
      expect(repository.historyCalls, 1);
    });

    test('returns typed failure when period crosses revisions', () async {
      final repository = _FakeRepository([
        _revision(
          id: 'old',
          from: BusinessDate(year: 2026, month: 1, day: 1),
          to: BusinessDate(year: 2026, month: 9, day: 14),
        ),
        _revision(
          id: 'new',
          from: BusinessDate(year: 2026, month: 9, day: 15),
          to: null,
        ),
      ]);
      final useCase = ResolveDriverCompensationForPeriodUseCase(repository);

      final result = await useCase(
        ResolveDriverCompensationForPeriodParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: 'driver-1',
          periodStart: BusinessDate(year: 2026, month: 9, day: 1),
          periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
        ),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.conflictPeriodSpansRevisions,
      );
    });

    test('rejects roles without compensation view permission', () async {
      final repository = _FakeRepository([]);
      final useCase = ResolveDriverCompensationForPeriodUseCase(repository);

      final result = await useCase(
        ResolveDriverCompensationForPeriodParams(
          currentCompanyContext: _context(CompanyRole.operations),
          driverId: 'driver-1',
          periodStart: BusinessDate(year: 2026, month: 9, day: 1),
          periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
        ),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.permissionView,
      );
      expect(repository.historyCalls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

DriverCompensationRevision _revision({
  required String id,
  required BusinessDate from,
  required BusinessDate? to,
}) {
  return DriverCompensationRevision(
    id: id,
    companyId: 'company-1',
    driverId: 'driver-1',
    amount: Money(
      minorUnits: 500000,
      currency: CurrencyCode.tryParse('AED')!,
    ),
    currencyFractionDigits: 2,
    effectiveFrom: from,
    effectiveTo: to,
  );
}

final class _FakeRepository implements DriverCompensationRepository {
  final List<DriverCompensationRevision> history;
  int historyCalls = 0;

  _FakeRepository(this.history);

  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    historyCalls += 1;
    return Success(List.unmodifiable(history));
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  }) {
    throw UnimplementedError();
  }
}
