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
import 'package:horus_system/features/drivers/domain/usecases/create_driver_compensation_revision_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/end_driver_compensation_revision_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_date_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('CreateDriverCompensationRevisionUseCase', () {
    test('creates exact-money revision for owner', () async {
      final repository = _FakeDriverCompensationRepository();
      final useCase = CreateDriverCompensationRevisionUseCase(repository);
      final amount = _money(500000, 'AED');

      final result = await useCase(
        CreateDriverCompensationRevisionParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: 'driver-1',
          amount: amount,
          effectiveFrom: BusinessDate(year: 2026, month: 1, day: 1),
          contractReference: 'EMP-001',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(repository.createCalls, 1);
      expect(repository.lastWriteData?.amount, amount);
      expect(repository.lastWriteData?.currencyFractionDigits, 2);
      expect(repository.lastWriteData?.contractReference, 'EMP-001');
    });

    test('rejects accountant management before repository mutation', () async {
      final repository = _FakeDriverCompensationRepository();
      final useCase = CreateDriverCompensationRevisionUseCase(repository);

      final result = await useCase(
        CreateDriverCompensationRevisionParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: 'driver-1',
          amount: _money(500000, 'AED'),
          effectiveFrom: BusinessDate(year: 2026, month: 1, day: 1),
        ),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.permissionManage,
      );
      expect(repository.createCalls, 0);
    });

    test(
      'rejects amount in a currency different from company currency',
      () async {
        final repository = _FakeDriverCompensationRepository();
        final useCase = CreateDriverCompensationRevisionUseCase(repository);

        final result = await useCase(
          CreateDriverCompensationRevisionParams(
            currentCompanyContext: _context(CompanyRole.owner),
            driverId: 'driver-1',
            amount: _money(500000, 'USD'),
            effectiveFrom: BusinessDate(year: 2026, month: 1, day: 1),
          ),
        );

        expect(
          result.failureOrNull?.code,
          DriverCompensationFailureCodes.validationCurrencyMismatch,
        );
        expect(repository.createCalls, 0);
      },
    );

    test('rejects a revision that overlaps existing history', () async {
      final repository = _FakeDriverCompensationRepository(
        history: [
          _revision(
            id: 'existing',
            amountMinorUnits: 500000,
            from: BusinessDate(year: 2026, month: 1, day: 1),
            to: BusinessDate(year: 2026, month: 7, day: 31),
          ),
        ],
      );
      final useCase = CreateDriverCompensationRevisionUseCase(repository);

      final result = await useCase(
        CreateDriverCompensationRevisionParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: 'driver-1',
          amount: _money(550000, 'AED'),
          effectiveFrom: BusinessDate(year: 2026, month: 7, day: 31),
        ),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.conflictOverlap,
      );
      expect(repository.createCalls, 0);
    });
  });

  group('ResolveDriverCompensationForDateUseCase', () {
    test(
      'resolves historical and current revisions by business date',
      () async {
        final januaryRevision = _revision(
          id: 'jan-contract',
          amountMinorUnits: 500000,
          from: BusinessDate(year: 2026, month: 1, day: 1),
          to: BusinessDate(year: 2026, month: 7, day: 31),
        );
        final augustRevision = _revision(
          id: 'aug-contract',
          amountMinorUnits: 550000,
          from: BusinessDate(year: 2026, month: 8, day: 1),
          to: null,
        );
        final repository = _FakeDriverCompensationRepository(
          history: [augustRevision, januaryRevision],
        );
        final useCase = ResolveDriverCompensationForDateUseCase(repository);
        final context = _context(CompanyRole.accountant);

        final july = await useCase(
          ResolveDriverCompensationForDateParams(
            currentCompanyContext: context,
            driverId: 'driver-1',
            targetDate: BusinessDate(year: 2026, month: 7, day: 1),
          ),
        );
        final september = await useCase(
          ResolveDriverCompensationForDateParams(
            currentCompanyContext: context,
            driverId: 'driver-1',
            targetDate: BusinessDate(year: 2026, month: 9, day: 1),
          ),
        );

        expect(july.dataOrNull?.id, 'jan-contract');
        expect(july.dataOrNull?.amount.minorUnits, 500000);
        expect(september.dataOrNull?.id, 'aug-contract');
        expect(september.dataOrNull?.amount.minorUnits, 550000);
        expect(januaryRevision.amount.minorUnits, 500000);
      },
    );

    test('returns typed not-found failure for an intentional gap', () async {
      final repository = _FakeDriverCompensationRepository(
        history: [
          _revision(
            id: 'jan-contract',
            amountMinorUnits: 500000,
            from: BusinessDate(year: 2026, month: 1, day: 1),
            to: BusinessDate(year: 2026, month: 1, day: 31),
          ),
        ],
      );
      final useCase = ResolveDriverCompensationForDateUseCase(repository);

      final result = await useCase(
        ResolveDriverCompensationForDateParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: 'driver-1',
          targetDate: BusinessDate(year: 2026, month: 2, day: 1),
        ),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.notFoundForDate,
      );
    });
  });

  group('ResolveDriverCompensationForPeriodUseCase', () {
    test('resolves the single revision covering the full period', () async {
      final revision = _revision(
        id: 'full-period-contract',
        amountMinorUnits: 550000,
        from: BusinessDate(year: 2026, month: 8, day: 1),
        to: null,
      );
      final repository = _FakeDriverCompensationRepository(
        history: [revision],
      );
      final useCase = ResolveDriverCompensationForPeriodUseCase(repository);

      final result = await useCase(
        ResolveDriverCompensationForPeriodParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: 'driver-1',
          periodStart: BusinessDate(year: 2026, month: 9, day: 1),
          periodEnd: BusinessDate(year: 2026, month: 9, day: 30),
        ),
      );

      expect(result.dataOrNull?.id, 'full-period-contract');
      expect(result.dataOrNull?.amount.minorUnits, 550000);
    });

    test('rejects a period spanning compensation revisions', () async {
      final repository = _FakeDriverCompensationRepository(
        history: [
          _revision(
            id: 'old-contract',
            amountMinorUnits: 500000,
            from: BusinessDate(year: 2026, month: 1, day: 1),
            to: BusinessDate(year: 2026, month: 9, day: 15),
          ),
          _revision(
            id: 'new-contract',
            amountMinorUnits: 550000,
            from: BusinessDate(year: 2026, month: 9, day: 16),
            to: null,
          ),
        ],
      );
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
        DriverCompensationFailureCodes.notFoundForPeriod,
      );
    });
  });

  group('EndDriverCompensationRevisionUseCase', () {
    test('prevents rewriting an already-ended revision', () async {
      final repository = _FakeDriverCompensationRepository();
      final useCase = EndDriverCompensationRevisionUseCase(repository);
      final revision = _revision(
        id: 'ended',
        amountMinorUnits: 500000,
        from: BusinessDate(year: 2026, month: 1, day: 1),
        to: BusinessDate(year: 2026, month: 7, day: 31),
      );

      final result = await useCase(
        EndDriverCompensationRevisionParams(
          currentCompanyContext: _context(CompanyRole.owner),
          revision: revision,
          effectiveTo: BusinessDate(year: 2026, month: 6, day: 30),
        ),
      );

      expect(
        result.failureOrNull?.code,
        DriverCompensationFailureCodes.conflictRevisionAlreadyEnded,
      );
      expect(repository.endCalls, 0);
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

Money _money(int minorUnits, String currencyCode) {
  return Money(
    minorUnits: minorUnits,
    currency: CurrencyCode.tryParse(currencyCode)!,
  );
}

DriverCompensationRevision _revision({
  required String id,
  required int amountMinorUnits,
  required BusinessDate from,
  required BusinessDate? to,
}) {
  return DriverCompensationRevision(
    id: id,
    companyId: 'company-1',
    driverId: 'driver-1',
    amount: _money(amountMinorUnits, 'AED'),
    currencyFractionDigits: 2,
    effectiveFrom: from,
    effectiveTo: to,
  );
}

final class _FakeDriverCompensationRepository
    implements DriverCompensationRepository {
  final List<DriverCompensationRevision> history;
  int createCalls = 0;
  int endCalls = 0;
  DriverCompensationWriteData? lastWriteData;

  _FakeDriverCompensationRepository({List<DriverCompensationRevision>? history})
    : history = history ?? <DriverCompensationRevision>[];

  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    return Success(List<DriverCompensationRevision>.unmodifiable(history));
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) async {
    createCalls += 1;
    lastWriteData = data;
    return Success(
      DriverCompensationRevision(
        id: 'created-revision',
        companyId: data.companyId,
        driverId: data.driverId,
        amount: data.amount,
        currencyFractionDigits: data.currencyFractionDigits,
        effectiveFrom: data.effectiveFrom,
        effectiveTo: data.effectiveTo,
        contractReference: data.contractReference,
      ),
    );
  }

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  }) async {
    endCalls += 1;
    final revision = history.firstWhere((item) => item.id == revisionId);
    return Success(
      DriverCompensationRevision(
        id: revision.id,
        companyId: revision.companyId,
        driverId: revision.driverId,
        amount: revision.amount,
        currencyFractionDigits: revision.currencyFractionDigits,
        effectiveFrom: revision.effectiveFrom,
        effectiveTo: effectiveTo,
        contractReference: revision.contractReference,
        contractDocumentReference: revision.contractDocumentReference,
      ),
    );
  }

  @override
  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  }) async {
    return Success(revision);
  }

  @override
  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  }) async {
    return const Success(BusinessDocumentAccess('https://example.test'));
  }
}
