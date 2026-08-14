import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
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

  group('DriverDetailsDialog audit localization', () {
    testWidgets('does not expose raw audit role or action in Arabic', (
      tester,
    ) async {
      await _pumpDialog(tester, locale: const Locale('ar'));

      expect(find.text('المحاسب'), findsOneWidget);
      expect(find.text('تم تغيير الحالة'), findsOneWidget);
      expect(find.textContaining('المحاسب'), findsAtLeastNWidgets(2));
      expect(find.textContaining('accountant'), findsNothing);
      expect(find.textContaining('status_changed'), findsNothing);
    });

    testWidgets('does not expose raw audit role or action in English', (
      tester,
    ) async {
      await _pumpDialog(tester, locale: const Locale('en'));

      expect(find.text('Accountant'), findsOneWidget);
      expect(find.text('Status changed'), findsOneWidget);
      expect(find.textContaining('Accountant'), findsAtLeastNWidgets(2));
      expect(find.textContaining('accountant'), findsNothing);
      expect(find.textContaining('status_changed'), findsNothing);
    });

    testWidgets(
      'normalizes license dates and image changes in audit timeline',
      (tester) async {
        final imageAuditLog = AuditLog(
          id: 'audit-2',
          companyId: _companyId,
          actorRole: 'owner',
          actorDisplayName: 'Mina Aly',
          module: AuditModule.drivers,
          entityType: AuditEntityType.driver,
          entityId: _driverId,
          entityDisplayName: 'test driver2',
          action: AuditAction.updated,
          description: 'driver_updated',
          oldValues: const {
            'license_expiry_date': '2026-08-18T20:00:00.000Z',
            'national_id_image_path': 'old-path',
          },
          newValues: const {
            'license_expiry_date': '2026-08-17T20:00:00.000Z',
            'national_id_image_path': 'new-path',
          },
          createdAt: DateTime.utc(2026, 8, 14, 20, 47),
        );

        await _pumpDialog(
          tester,
          locale: const Locale('en'),
          state: _state.copyWith(selectedDriverActivity: [imageAuditLog]),
        );

        expect(find.textContaining('License expiry date:'), findsNothing);
        expect(find.textContaining('National ID front image:'), findsOneWidget);
        expect(find.textContaining('Existing image'), findsOneWidget);
        expect(find.textContaining('Updated image'), findsOneWidget);
        expect(find.textContaining('National ID image:'), findsNothing);
        expect(
          find.textContaining('Image uploaded → Image uploaded'),
          findsNothing,
        );
        expect(find.textContaining('T20:00:00.000Z'), findsNothing);
      },
    );
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

final _auditLog = AuditLog(
  id: 'audit-1',
  companyId: _companyId,
  actorRole: 'accountant',
  actorDisplayName: 'Test Accountant',
  module: AuditModule.drivers,
  entityType: AuditEntityType.driver,
  entityId: _driverId,
  entityDisplayName: 'test driver2',
  action: AuditAction.statusChanged,
  description: 'driver_status_changed',
  oldValues: const {'is_active': false},
  newValues: const {'is_active': true},
  createdAt: DateTime.utc(2026, 7, 22, 8, 30),
);

final _state = DriversLoaded(
  currentCompanyContext: _companyContext,
  allDrivers: [_driver],
  canManageDrivers: true,
  canManageDriverFinance: true,
  selectedDriver: _driver,
  selectedDriverActivity: [_auditLog],
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

Future<void> _pumpDialog(
  WidgetTester tester, {
  required Locale locale,
  DriversLoaded? state,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DriverDetailsDialog(
          driver: _driver,
          state: state ?? _state,
          onAddAdvance: () {},
          onAddDriverCharge: () {},
          onAddCashReturn: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
