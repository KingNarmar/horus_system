import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/constants/app_icons.dart';
import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/drivers/domain/entities/driver.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_urls.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/repositories/drivers_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/add_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/can_manage_drivers_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/deactivate_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_image_urls_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_drivers_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/reactivate_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/update_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/attach_driver_compensation_contract_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/create_driver_compensation_revision_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/end_driver_compensation_revision_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_compensation_contract_access_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_compensation_history_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_date_usecase.dart';
import 'package:horus_system/features/drivers/presentation/cubit/driver_compensation_cubit.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_cubit.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_state.dart';
import 'package:horus_system/features/drivers/presentation/pages/drivers_page.dart';
import 'package:horus_system/features/drivers/presentation/widgets/driver_details_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  for (final role in [CompanyRole.owner, CompanyRole.admin]) {
    testWidgets(
      'driver details inherits both scoped cubits for ${role.value}',
      (tester) async {
        final dateUseCase = GetCompanyBusinessDateUseCase(
          _BusinessDateProvider(),
        );
        final driversRepo = _DriversRepository();
        final compensationRepo = _CompensationRepository();
        final driversCubit = DriversCubit(
          getDriversUseCase: GetDriversUseCase(driversRepo),
          canManageDriversUseCase: const CanManageDriversUseCase(),
          getDriverImageUrlsUseCase: GetDriverImageUrlsUseCase(driversRepo),
          addDriverUseCase: AddDriverUseCase(driversRepo),
          updateDriverUseCase: UpdateDriverUseCase(driversRepo),
          deactivateDriverUseCase: DeactivateDriverUseCase(driversRepo),
          reactivateDriverUseCase: ReactivateDriverUseCase(driversRepo),
          getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
            _AuditLogRepository(),
          ),
          convertInstantsToBusinessLocalDateTimesUseCase:
              const ConvertInstantsToBusinessLocalDateTimesUseCase(
                _BusinessTimeZoneConverter(),
              ),
          getCompanyBusinessDateUseCase: dateUseCase,
        );
        final compensationCubit = DriverCompensationCubit(
          getCompanyBusinessDateUseCase: dateUseCase,
          getHistoryUseCase: GetDriverCompensationHistoryUseCase(
            compensationRepo,
          ),
          resolveForDateUseCase: ResolveDriverCompensationForDateUseCase(
            compensationRepo,
          ),
          createRevisionUseCase: CreateDriverCompensationRevisionUseCase(
            compensationRepo,
          ),
          endRevisionUseCase: EndDriverCompensationRevisionUseCase(
            compensationRepo,
          ),
          attachContractUseCase: AttachDriverCompensationContractUseCase(
            compensationRepo,
          ),
          contractAccessUseCase: GetDriverCompensationContractAccessUseCase(
            compensationRepo,
          ),
        );
        addTearDown(driversCubit.close);
        addTearDown(compensationCubit.close);

        // Both providers are under the Navigator's route. A showDialog
        // route cannot implicitly access them without explicit forwarding.
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<DriversCubit>.value(value: driversCubit),
                BlocProvider<DriverCompensationCubit>.value(
                  value: compensationCubit,
                ),
              ],
              child: Scaffold(
                body: DriversPage(
                  currentCompanyContext: CurrentCompanyContext(
                    company: _company,
                    role: role,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.view), findsOneWidget);
        await tester.tap(find.byIcon(AppIcons.view));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(DriverDetailsDialog), findsOneWidget);
        expect(find.textContaining(_driver.fullName), findsWidgets);
        expect((driversCubit.state as DriversLoaded).selectedDriver?.id,
            _driver.id);
        expect(find.text('QA Operator'), findsWidgets);

        await tester.tap(
          find.descendant(
            of: find.byType(DriverDetailsDialog),
            matching: find.byIcon(AppIcons.clear),
          ).first,
        );
        await tester.pumpAndSettle();
        expect(find.byType(DriverDetailsDialog), findsNothing);
      },
    );
  }
}

const _company = Company(
  id: 'company-qa',
  name: 'H.O.R.U.S QA',
  businessTimezone: 'Asia/Dubai',
  baseCurrencyCode: 'AED',
  baseCurrencyFractionDigits: 2,
);

const _driver = Driver(
  id: 'driver-qa',
  companyId: 'company-qa',
  fullName: 'HORUS Storage QA Driver',
  status: DriverStatus.active,
);

final class _DriversRepository extends Fake implements DriversRepository {
  @override
  Future<Result<List<Driver>>> getDrivers({
    required String companyId,
  }) async => const Success(<Driver>[_driver]);

  @override
  Future<Result<DriverImageUrls>> getDriverImageUrls({
    required Driver driver,
  }) async => const Success(DriverImageUrls.empty);
}

final class _CompensationRepository extends Fake
    implements DriverCompensationRepository {
  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) async => const Success(<DriverCompensationRevision>[]);
}

final class _BusinessDateProvider implements CompanyBusinessDateProvider {
  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async => Success(BusinessDate(year: 2026, month: 11, day: 2));
}

final class _AuditLogRepository extends Fake implements AuditLogRepository {
  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async => Success(<AuditLog>[
    AuditLog(
      id: 'audit-qa',
      companyId: companyId,
      module: module,
      entityType: entityType,
      entityId: entityId,
      action: AuditAction.created,
      description: 'driver.created',
      actorRole: 'owner',
      actorDisplayName: 'QA Operator',
      createdAt: DateTime.utc(2026, 11, 2),
    ),
  ]);
}

final class _BusinessTimeZoneConverter implements BusinessTimeZoneConverter {
  const _BusinessTimeZoneConverter();

  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) => Success(
    BusinessLocalDateTime(
      year: instant.year,
      month: instant.month,
      day: instant.day,
      hour: instant.hour,
      minute: instant.minute,
    ),
  );

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) => Success(DateTime.utc(
    localDateTime.year,
    localDateTime.month,
    localDateTime.day,
    localDateTime.hour,
    localDateTime.minute,
  ));
}
