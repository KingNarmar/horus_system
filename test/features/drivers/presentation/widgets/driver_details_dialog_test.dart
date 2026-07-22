import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/drivers/domain/entities/driver.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_state.dart';
import 'package:horus_system/features/drivers/presentation/widgets/driver_details_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  group('DriverDetailsDialog responsive layout', () {
    testWidgets('stacks Arabic labels and values on mobile without overflow', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(390, 844));
      await _pumpDialog(tester, locale: const Locale('ar'));

      expect(tester.takeException(), isNull);
      expect(find.text(_phone), findsOneWidget);
      expect(find.text('السائق مدين للشركة: 5600.00'), findsOneWidget);

      final labelBottom = tester.getBottomLeft(find.text('الهاتف')).dy;
      final valueTop = tester.getTopLeft(find.text(_phone)).dy;
      expect(valueTop, greaterThan(labelBottom));
    });

    testWidgets('keeps Arabic labels and values horizontal on tablet', (
      tester,
    ) async {
      await _setSurfaceSize(tester, const Size(800, 1000));
      await _pumpDialog(tester, locale: const Locale('ar'));

      expect(tester.takeException(), isNull);

      final labelTop = tester.getTopLeft(find.text('الهاتف')).dy;
      final valueTop = tester.getTopLeft(find.text(_phone)).dy;
      expect((labelTop - valueTop).abs(), lessThan(2));
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _phone = '+21812181212';

const _companyContext = CurrentCompanyContext(
  company: Company(id: _companyId, name: 'Test Company'),
  role: CompanyRole.accountant,
);

final _driver = Driver(
  id: _driverId,
  companyId: _companyId,
  fullName: 'test driver2',
  phone: _phone,
  nationalId: '84514850',
  licenseNumber: '181218451',
  licenseExpiryDate: DateTime(2026, 6, 29),
  status: DriverStatus.active,
);

final _state = DriversLoaded(
  currentCompanyContext: _companyContext,
  allDrivers: [_driver],
  canManageDrivers: true,
  canManageDriverFinance: true,
  selectedDriver: _driver,
  selectedDriverBalance: DriverBalance(
    companyId: _companyId,
    driverId: _driverId,
    checkpoint: DriverBalanceCheckpoint(
      settlementId: 'settlement-1',
      periodEnd: DateTime(2026, 8, 31),
      snapshotCreatedAt: DateTime.utc(2026, 7, 15, 4, 59),
      closingBalance: -5600,
    ),
    totalAdvances: 0,
    totalDriverCharges: 0,
  ),
  selectedDriverFinancialMovements: [
    DriverFinancialMovement(
      id: 'movement-1',
      companyId: _companyId,
      driverId: _driverId,
      type: DriverFinancialMovementType.advance,
      amount: 5000,
      movementDate: DateTime(2026, 6, 29),
    ),
  ],
);

Future<void> _setSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

Future<void> _pumpDialog(WidgetTester tester, {required Locale locale}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DriverDetailsDialog(
          driver: _driver,
          state: _state,
          onAddAdvance: () {},
          onAddDriverCharge: () {},
          onAddCashReturn: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
