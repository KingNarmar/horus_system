import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_source_type.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlements_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_cubit.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_state.dart';
import 'package:horus_system/features/driver_settlements/presentation/widgets/driver_settlement_details_dialog.dart';
import 'package:horus_system/features/driver_settlements/presentation/widgets/driver_settlement_form_dialog.dart';
import 'package:horus_system/features/driver_settlements/presentation/widgets/driver_settlement_void_dialog.dart';
import 'package:horus_system/features/driver_settlements/presentation/widgets/driver_settlements_state_view.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  group('Driver Settlements widgets', () {
    testWidgets('stacks detail values on Arabic mobile without overflow', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        child: DriverSettlementDetailsDialog(
          state: _loadedState(selectedSettlement: _settlement),
          onRetry: () {},
          onFinalize: (_) async {},
          onVoid: (_) async {},
        ),
      );

      expect(tester.takeException(), isNull);
      final labelBottom = tester.getBottomLeft(find.text('الحالة')).dy;
      final valueTop = tester.getTopLeft(find.text('مسودة')).dy;
      expect(valueTop, greaterThan(labelBottom));
    });

    testWidgets('keeps detail values horizontal on Arabic tablet', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(800, 1000));
      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        child: DriverSettlementDetailsDialog(
          state: _loadedState(selectedSettlement: _settlement),
          onRetry: () {},
          onFinalize: (_) async {},
          onVoid: (_) async {},
        ),
      );

      expect(tester.takeException(), isNull);
      final labelTop = tester.getTopLeft(find.text('الحالة')).dy;
      final valueTop = tester.getTopLeft(find.text('مسودة')).dy;
      expect((labelTop - valueTop).abs(), lessThan(2));
    });

    testWidgets('uses the established standard dialog pattern on mobile', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        child: DriverSettlementDetailsDialog(
          state: _loadedState(selectedSettlement: _settlement),
          onRetry: () {},
          onFinalize: (_) async {},
          onVoid: (_) async {},
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps standard dialog actions reachable on mobile', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        child: DriverSettlementDetailsDialog(
          state: _loadedState(selectedSettlement: _longSettlement),
          onRetry: () {},
          onFinalize: (_) async {},
          onVoid: (_) async {},
        ),
      );

      final voidButton = find.byKey(
        const ValueKey('driverSettlementVoidButton'),
      );
      await tester.ensureVisible(voidButton);
      await tester.pumpAndSettle();

      final buttonRect = tester.getRect(voidButton);
      expect(buttonRect.top, lessThan(844));
      expect(buttonRect.bottom, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('distinguishes Arabic void action from cancel action', (
      tester,
    ) async {
      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        child: DriverSettlementDetailsDialog(
          state: _loadedState(selectedSettlement: _settlement),
          onRetry: () {},
          onFinalize: (_) async {},
          onVoid: (_) async {},
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'إبطال'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'إلغاء'), findsOneWidget);
    });

    testWidgets('requires a void reason', (tester) async {
      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        child: const DriverSettlementVoidDialog(),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Void'));
      await tester.pump();

      expect(find.text('Void reason is required.'), findsOneWidget);
    });

    testWidgets('shows localized permission failure without tenant data', (
      tester,
    ) async {
      await _pumpLocalized(
        tester,
        locale: const Locale('ar'),
        child: DriverSettlementsStateView(
          state: const DriverSettlementsFailure(
            PermissionFailure(
              code: FailureCodes.permissionDriverSettlementsView,
            ),
          ),
          onRetry: () {},
          onSearchChanged: (_) {},
          onDriverFilterChanged: (_) {},
          onStatusFilterChanged: (_) {},
          onIncludeVoidedChanged: (_) {},
          onViewDetails: (_) {},
        ),
      );

      expect(
        find.text('هذا الدور لا يمكنه عرض تسويات السائقين.'),
        findsOneWidget,
      );
    });

    testWidgets('form stacks dates and requires driver before preview', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      final repository = _FakeDriverSettlementsRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      await cubit.loadDriverSettlements(_companyContext);

      await _pumpLocalized(
        tester,
        locale: const Locale('en'),
        child: BlocProvider.value(
          value: cubit,
          child: const DriverSettlementFormDialog(
            driverOptions: [_activeDriver],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final startTop = tester
          .getTopLeft(find.byKey(const ValueKey('driverSettlementPeriodStart')))
          .dy;
      final endTop = tester
          .getTopLeft(find.byKey(const ValueKey('driverSettlementPeriodEnd')))
          .dy;
      expect(endTop, greaterThan(startTop));

      final saveButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('driverSettlementSaveDraftButton')),
      );
      expect(saveButton.onPressed, isNull);

      await tester.tap(
        find.byKey(const ValueKey('driverSettlementCalculatePreviewButton')),
      );
      await tester.pump();

      expect(find.text('Select a driver.'), findsOneWidget);
      expect(repository.snapshotCalls, 0);
    });
  });
}

const _companyContext = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Test Company'),
  role: CompanyRole.accountant,
);

const _activeDriver = DriverSettlementDriverOption(
  id: 'driver-1',
  displayName: 'Driver One',
  isActive: true,
);

final _settlement = DriverSettlement(
  id: 'settlement-1',
  companyId: 'company-1',
  driverId: 'driver-1',
  period: DriverSettlementPeriod(
    start: DateTime(2026, 7, 1),
    end: DateTime(2026, 7, 31),
  ),
  calculation: const DriverSettlementCalculationResult(
    openingDriverBalance: -5600,
    advancesTotal: 100,
    driverPaidTripExpensesTotal: 0,
    returnedCashTotal: 100,
    deductionsTotal: 0,
    settlementDeductionsTotal: 0,
    grossSalary: 1000,
    salaryDeductionsTotal: 100,
    balanceDeductionApplied: 900,
    netSalaryPayable: 0,
    closingDriverBalance: -5600,
  ),
  status: DriverSettlementStatus.draft,
);

final _longSettlement = DriverSettlement(
  id: 'settlement-1',
  companyId: 'company-1',
  driverId: 'driver-1',
  period: DriverSettlementPeriod(
    start: DateTime(2026, 7, 1),
    end: DateTime(2026, 7, 31),
  ),
  calculation: const DriverSettlementCalculationResult(
    openingDriverBalance: -5600,
    advancesTotal: 100,
    driverPaidTripExpensesTotal: 0,
    returnedCashTotal: 100,
    deductionsTotal: 0,
    settlementDeductionsTotal: 0,
    grossSalary: 1000,
    salaryDeductionsTotal: 100,
    balanceDeductionApplied: 900,
    netSalaryPayable: 0,
    closingDriverBalance: -5600,
  ),
  status: DriverSettlementStatus.draft,
  notes: 'Responsive dialog regression test',
  items: List.generate(
    8,
    (index) => DriverSettlementItem(
      companyId: 'company-1',
      settlementId: 'settlement-1',
      sourceType: DriverSettlementItemSourceType.driverFinancialMovement,
      sourceId: 'movement-$index',
      sourceDate: DateTime(2026, 7, index + 1),
      direction: index.isEven
          ? DriverSettlementItemDirection.driverToCompany
          : DriverSettlementItemDirection.companyToDriver,
      amount: 100 + index.toDouble(),
      labelKey: 'advance',
      descriptionKey: 'Movement $index',
    ),
  ),
);

DriverSettlementsLoaded _loadedState({
  required DriverSettlement selectedSettlement,
}) {
  return DriverSettlementsLoaded(
    currentCompanyContext: _companyContext,
    allSettlements: [selectedSettlement],
    driverOptions: const [_activeDriver],
    canManageDriverSettlements: true,
    selectedSettlement: selectedSettlement,
  );
}

DriverSettlementsCubit _cubit(_FakeDriverSettlementsRepository repository) {
  return DriverSettlementsCubit(
    getDriverSettlementsUseCase: GetDriverSettlementsUseCase(repository),
    getDriverOptionsUseCase: GetDriverSettlementDriverOptionsUseCase(
      repository,
    ),
    getDriverSettlementDetailsUseCase: GetDriverSettlementDetailsUseCase(
      repository,
    ),
    calculatePreviewUseCase: CalculateDriverSettlementPreviewUseCase(
      repository,
    ),
    createDraftUseCase: CreateDriverSettlementDraftUseCase(repository),
    finalizeSettlementUseCase: FinalizeDriverSettlementUseCase(repository),
    voidSettlementUseCase: VoidDriverSettlementUseCase(repository),
    getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
      _FakeAuditLogRepository(),
    ),
  );
}

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _pumpLocalized(
  WidgetTester tester, {
  required Locale locale,
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeDriverSettlementsRepository implements DriverSettlementsRepository {
  int snapshotCalls = 0;

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) async {
    return const Success([_activeDriver]);
  }

  @override
  Future<Result<DriverSettlementDriverOption?>> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    return const Success(_activeDriver);
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    return Success(_settlement);
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    snapshotCalls++;
    return const Success(DriverSettlementSourceSnapshot());
  }

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) async {
    return Success(_settlement);
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) async {
    return Success(_settlement);
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) async {
    return Success(_settlement);
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success([]);
  }
}
