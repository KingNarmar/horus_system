import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
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
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_state.dart';
import 'package:horus_system/features/driver_settlements/presentation/widgets/driver_settlement_details_dialog.dart';
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

BusinessDate _date(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

final _settlement = DriverSettlement(
  id: 'settlement-1',
  companyId: 'company-1',
  driverId: 'driver-1',
  period: DriverSettlementPeriod(
    start: _date(2026, 7, 1),
    end: _date(2026, 7, 31),
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
    start: _date(2026, 7, 1),
    end: _date(2026, 7, 31),
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
      sourceDate: _date(2026, 7, index + 1),
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
    businessDate: _date(2026, 7, 31),
    allSettlements: [selectedSettlement],
    driverOptions: const [_activeDriver],
    canManageDriverSettlements: true,
    selectedSettlement: selectedSettlement,
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
