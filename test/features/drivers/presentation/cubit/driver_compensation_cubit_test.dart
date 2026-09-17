import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/failures/driver_compensation_failure_codes.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/attach_driver_compensation_contract_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/create_driver_compensation_revision_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/end_driver_compensation_revision_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_compensation_contract_access_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_compensation_history_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_date_usecase.dart';
import 'package:horus_system/features/drivers/presentation/cubit/driver_compensation_cubit.dart';
import 'package:horus_system/features/drivers/presentation/cubit/driver_compensation_state.dart';
import 'package:test/test.dart';

void main() {
  group('DriverCompensationCubit', () {
    test(
      'loads history and resolves revision for company business date',
      () async {
        final repository = _FakeRepository(
          history: [
            _revision(
              id: 'old',
              from: BusinessDate(year: 2026, month: 1, day: 1),
              to: BusinessDate(year: 2026, month: 7, day: 31),
            ),
            _revision(
              id: 'current',
              from: BusinessDate(year: 2026, month: 8, day: 1),
              to: null,
            ),
          ],
        );
        final cubit = _cubit(
          repository,
          businessDate: BusinessDate(year: 2026, month: 9, day: 16),
        );
        addTearDown(cubit.close);

        await cubit.loadForDriver(
          currentCompanyContext: _ownerContext,
          driverId: _driverId,
        );

        final state = cubit.state as DriverCompensationLoaded;
        expect(state.history, hasLength(2));
        expect(state.currentRevision?.id, 'current');
        expect(state.currentResolutionFailure, isNull);
        expect(state.businessDate, BusinessDate(year: 2026, month: 9, day: 16));
      },
    );

    test(
      'keeps loaded history and exposes typed gap resolution failure',
      () async {
        final repository = _FakeRepository(
          history: [
            _revision(
              id: 'old',
              from: BusinessDate(year: 2026, month: 1, day: 1),
              to: BusinessDate(year: 2026, month: 7, day: 31),
            ),
          ],
        );
        final cubit = _cubit(
          repository,
          businessDate: BusinessDate(year: 2026, month: 9, day: 16),
        );
        addTearDown(cubit.close);

        await cubit.loadForDriver(
          currentCompanyContext: _ownerContext,
          driverId: _driverId,
        );

        final state = cubit.state as DriverCompensationLoaded;
        expect(state.history.single.id, 'old');
        expect(state.currentRevision, isNull);
        expect(
          state.currentResolutionFailure?.code,
          DriverCompensationFailureCodes.notFoundForDate,
        );
      },
    );

    test(
      'returns mutation failure and keeps loaded state on failed create',
      () async {
        final repository = _FakeRepository(
          createFailure: const ConflictFailure(
            code: DriverCompensationFailureCodes.conflictOverlap,
          ),
        );
        final cubit = _cubit(repository);
        addTearDown(cubit.close);
        await cubit.loadForDriver(
          currentCompanyContext: _ownerContext,
          driverId: _driverId,
        );

        final failure = await cubit.createRevision(
          amount: _money(550000),
          effectiveFrom: BusinessDate(year: 2026, month: 8, day: 1),
        );

        expect(failure?.code, DriverCompensationFailureCodes.conflictOverlap);
        final state = cubit.state as DriverCompensationLoaded;
        expect(state.isSaving, isFalse);
        expect(
          state.mutationFailure?.code,
          DriverCompensationFailureCodes.conflictOverlap,
        );
      },
    );

    test('reloads history after successful create', () async {
      final repository = _FakeRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.loadForDriver(
        currentCompanyContext: _ownerContext,
        driverId: _driverId,
      );
      final initialHistoryCalls = repository.historyCalls;

      final failure = await cubit.createRevision(
        amount: _money(550000),
        effectiveFrom: BusinessDate(year: 2026, month: 8, day: 1),
      );

      expect(failure, isNull);
      expect(repository.createCalls, 1);
      expect(repository.historyCalls, greaterThan(initialHistoryCalls));
      final state = cubit.state as DriverCompensationLoaded;
      expect(state.history.single.amount.minorUnits, 550000);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

const _ownerContext = CurrentCompanyContext(
  company: Company(
    id: _companyId,
    name: 'Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
  ),
  role: CompanyRole.owner,
);

DriverCompensationCubit _cubit(
  _FakeRepository repository, {
  BusinessDate? businessDate,
}) {
  final dateProvider = _FakeBusinessDateProvider(
    businessDate ?? BusinessDate(year: 2026, month: 7, day: 1),
  );
  return DriverCompensationCubit(
    getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(dateProvider),
    getHistoryUseCase: GetDriverCompensationHistoryUseCase(repository),
    resolveForDateUseCase: ResolveDriverCompensationForDateUseCase(repository),
    createRevisionUseCase: CreateDriverCompensationRevisionUseCase(repository),
    endRevisionUseCase: EndDriverCompensationRevisionUseCase(repository),
    attachContractUseCase: AttachDriverCompensationContractUseCase(repository),
    contractAccessUseCase: GetDriverCompensationContractAccessUseCase(
      repository,
    ),
  );
}

Money _money(int minorUnits) {
  return Money(minorUnits: minorUnits, currency: CurrencyCode.tryParse('AED')!);
}

DriverCompensationRevision _revision({
  required String id,
  required BusinessDate from,
  required BusinessDate? to,
  int minorUnits = 500000,
}) {
  return DriverCompensationRevision(
    id: id,
    companyId: _companyId,
    driverId: _driverId,
    amount: _money(minorUnits),
    currencyFractionDigits: 2,
    effectiveFrom: from,
    effectiveTo: to,
  );
}

final class _FakeBusinessDateProvider implements CompanyBusinessDateProvider {
  final BusinessDate date;

  _FakeBusinessDateProvider(this.date);

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    return Success(date);
  }
}

final class _FakeRepository implements DriverCompensationRepository {
  final List<DriverCompensationRevision> history;
  final ConflictFailure? createFailure;
  int historyCalls = 0;
  int createCalls = 0;

  _FakeRepository({
    List<DriverCompensationRevision>? history,
    this.createFailure,
  }) : history = history ?? <DriverCompensationRevision>[];

  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    historyCalls += 1;
    return Success(List<DriverCompensationRevision>.unmodifiable(history));
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) async {
    createCalls += 1;
    final failure = createFailure;
    if (failure != null) return FailureResult(failure);
    final revision = DriverCompensationRevision(
      id: 'created',
      companyId: data.companyId,
      driverId: data.driverId,
      amount: data.amount,
      currencyFractionDigits: data.currencyFractionDigits,
      effectiveFrom: data.effectiveFrom,
      effectiveTo: data.effectiveTo,
      contractReference: data.contractReference,
    );
    history
      ..clear()
      ..add(revision);
    return Success(revision);
  }

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  }) async {
    return Success(history.firstWhere((item) => item.id == revisionId));
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
