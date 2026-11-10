import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_entity.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status.dart';
import 'package:horus_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_cubit.dart';
import 'package:horus_system/features/fleet/presentation/cubit/fleet_state.dart';
import 'package:horus_system/features/fleet/presentation/pages/fleet_page.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

import '../../../../helpers/fake_business_time_zone_converter.dart';

const _companyContext = CurrentCompanyContext(
  company: Company(id: 'fleet-test-company', name: 'Fleet Test Company'),
  role: CompanyRole.owner,
);
const _tractor = TractorHead(
  id: 'tractor-1',
  companyId: 'fleet-test-company',
  plateNumber: 'T-100',
  status: VehicleStatus.available,
  isActive: true,
);
const _inactiveTrailer = TrailerEntity(
  id: 'trailer-1',
  companyId: 'fleet-test-company',
  plateNumber: 'TR-100',
  status: VehicleStatus.available,
  isActive: false,
);
const _quotaFailure = ConflictFailure(
  code: QuotaFailureCodes.combinedVehiclesReached,
);

void main() {
  test(
    'denied creates preserve loaded assets, tab and individual feedback events',
    () async {
      final cubit = _realCubit();
      addTearDown(cubit.close);
      await cubit.loadFleet(_companyContext);
      cubit.selectTab(FleetAssetTab.trailers);

      await cubit.saveTrailer(
        plateNumber: 'TR-NEW',
        status: VehicleStatus.available,
      );
      final first = cubit.state as FleetLoaded;
      expect(first.allTractorHeads, [_tractor]);
      expect(first.allTrailers, [_inactiveTrailer]);
      expect(first.selectedTab, FleetAssetTab.trailers);
      expect(
        first.mutationFailure?.code,
        QuotaFailureCodes.combinedVehiclesReached,
      );
      expect(first.mutationFailureSequence, 1);

      await cubit.saveTractorHead(
        plateNumber: 'T-NEW',
        status: VehicleStatus.available,
      );
      final second = cubit.state as FleetLoaded;
      expect(second.allTractorHeads, [_tractor]);
      expect(second.allTrailers, [_inactiveTrailer]);
      expect(second.selectedTab, FleetAssetTab.trailers);
      expect(second.mutationFailureSequence, 2);
    },
  );

  test('denied trailer reactivation retains its inactive row', () async {
    final cubit = _realCubit();
    addTearDown(cubit.close);
    await cubit.loadFleet(_companyContext);

    await cubit.reactivateTrailer(_inactiveTrailer);
    final loaded = cubit.state as FleetLoaded;
    expect(loaded.allTrailers.single.isActive, isFalse);
    expect(loaded.allTractorHeads, [_tractor]);
    expect(loaded.mutationFailure, _quotaFailure);
    expect(loaded.activeStateChangingAssetIds, isEmpty);
    expect(loaded.mutationFailureSequence, 1);
  });

  for (final locale in [const Locale('en'), const Locale('ar')]) {
    testWidgets(
      'quota denial keeps fleet visible with localized one-shot feedback: ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final cubit = _PageFleetCubit();
        addTearDown(cubit.close);
        await tester.pumpWidget(
          BlocProvider<FleetCubit>.value(
            value: cubit,
            child: MaterialApp(
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: FleetPage(currentCompanyContext: _companyContext),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('T-100'), findsWidgets);
        cubit.publishQuotaFailure();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final translated = locale.languageCode == 'ar'
            ? AppLocalizationsAr().failureQuotaCombinedVehiclesReached
            : AppLocalizationsEn().failureQuotaCombinedVehiclesReached;
        expect(find.text(translated), findsOneWidget);
        expect(find.text('T-100'), findsWidgets);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.text(locale.languageCode == 'ar' ? 'إعادة المحاولة' : 'Retry'),
          findsNothing,
        );
        if (locale.languageCode == 'ar') {
          expect(
            Directionality.of(tester.element(find.byType(FleetPage))),
            TextDirection.rtl,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}

FleetCubit _realCubit() {
  final repo = _QuotaRepository();
  return FleetCubit(
    getTractorHeadsUseCase: GetTractorHeadsUseCase(repo),
    getTrailersUseCase: GetTrailersUseCase(repo),
    canManageFleetUseCase: const CanManageFleetUseCase(),
    saveTractorHeadUseCase: SaveTractorHeadUseCase(repo),
    saveTrailerUseCase: SaveTrailerUseCase(repo),
    deactivateTractorHeadUseCase: DeactivateTractorHeadUseCase(repo),
    reactivateTractorHeadUseCase: ReactivateTractorHeadUseCase(repo),
    deactivateTrailerUseCase: DeactivateTrailerUseCase(repo),
    reactivateTrailerUseCase: ReactivateTrailerUseCase(repo),
    getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(_NoAuditRepository()),
    convertInstantsToBusinessLocalDateTimesUseCase:
        const ConvertInstantsToBusinessLocalDateTimesUseCase(
          FakeBusinessTimeZoneConverter(),
        ),
    getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
      _FixedDateProvider(),
    ),
  );
}

class _QuotaRepository implements FleetRepository {
  @override
  Future<Result<List<TractorHead>>> getTractorHeads({
    required String companyId,
  }) async => const Success<List<TractorHead>>([_tractor]);

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({
    required String companyId,
  }) async => const Success<List<TrailerEntity>>([_inactiveTrailer]);

  @override
  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  }) async => const FailureResult<TractorHead>(_quotaFailure);

  @override
  Future<Result<TrailerEntity>> addTrailer({
    required TrailerWriteData data,
    required String actorRole,
  }) async => const FailureResult<TrailerEntity>(_quotaFailure);

  @override
  Future<Result<TrailerEntity>> reactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) async => const FailureResult<TrailerEntity>(_quotaFailure);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedDateProvider implements CompanyBusinessDateProvider {
  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async => Success(BusinessDate(year: 2026, month: 11, day: 10));
}

class _NoAuditRepository implements AuditLogRepository {
  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async => const Success<List<AuditLog>>([]);
}

/// Only the stream contract is faked here; Cubit mutation behavior is tested above.
class _PageFleetCubit extends Cubit<FleetState> implements FleetCubit {
  _PageFleetCubit()
    : super(
        const FleetLoaded(
          currentCompanyContext: _companyContext,
          allTractorHeads: [_tractor],
          allTrailers: [_inactiveTrailer],
          canManageFleet: true,
        ),
      );

  @override
  Future<void> loadFleet(CurrentCompanyContext _) async {}

  void publishQuotaFailure() {
    final current = state as FleetLoaded;
    emit(
      current.copyWith(
        mutationFailure: _quotaFailure,
        mutationFailureSequence: current.mutationFailureSequence + 1,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
