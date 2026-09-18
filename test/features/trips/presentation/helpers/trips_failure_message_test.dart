import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/trips/domain/failures/trip_failure_codes.dart';
import 'package:horus_system/features/trips/presentation/helpers/trips_failure_message.dart';
import 'package:horus_system/features/trips/presentation/localization/trips_localizations_x.dart';
import 'package:horus_system/features/trips/presentation/widgets/trip_details_helpers.dart';
import 'package:horus_system/l10n/app_localizations.dart';
import 'package:horus_system/l10n/app_localizations_ar.dart';
import 'package:horus_system/l10n/app_localizations_en.dart';

void main() {
  group('PC-07 Trip presentation hardening', () {
    test(
      'distinguishes agreed rate per ton from commercial amount in audit',
      () {
        final en = AppLocalizationsEn();
        final ar = AppLocalizationsAr();

        expect(
          en.tripAuditFieldLabel('agreed_freight_rate_per_ton'),
          'Freight / t',
        );
        expect(en.tripAuditFieldLabel('commercial_amount'), 'Freight');
        expect(en.tripAuditFieldLabel('freight_price'), 'Freight');
        expect(
          ar.tripAuditFieldLabel('agreed_freight_rate_per_ton'),
          'سعر النقل / طن',
        );
        expect(ar.tripAuditFieldLabel('commercial_amount'), 'سعر النقل');
        expect(ar.tripAuditFieldLabel('freight_price'), 'سعر النقل');
      },
    );

    test('keeps commercial snapshot fields visible in audit changes', () {
      final log = AuditLog(
        id: 'log-1',
        companyId: 'company-1',
        module: AuditModule.trips,
        entityType: AuditEntityType.trip,
        entityId: 'trip-1',
        action: AuditAction.updated,
        description: 'trip_updated',
        oldValues: const {
          'quantity_tons': '10.000',
          'agreed_freight_rate_per_ton': '15.00',
          'commercial_amount': '150.00',
        },
        newValues: const {
          'quantity_tons': '12.000',
          'agreed_freight_rate_per_ton': '16.00',
          'commercial_amount': '192.00',
        },
        createdAt: DateTime.utc(2026, 9, 16),
      );

      expect(visibleTripAuditChangeKeys(log), [
        'quantity_tons',
        'agreed_freight_rate_per_ton',
        'commercial_amount',
      ]);
    });

    testWidgets('localizes commercial input validation failures', (
      tester,
    ) async {
      const quantityFailure = ValidationFailure(
        code: FailureCodes.validationTripQuantityInvalid,
        message: 'raw quantity message',
      );
      const rateFailure = ValidationFailure(
        code: FailureCodes.validationTripFreightRateInvalid,
        message: 'raw rate message',
      );

      expect(
        await _messageFor(tester, const Locale('en'), quantityFailure),
        'Enter a valid non-negative number.',
      );
      expect(
        await _messageFor(tester, const Locale('ar'), quantityFailure),
        'أدخل رقم صحيح غير سالب.',
      );
      expect(
        await _messageFor(tester, const Locale('en'), rateFailure),
        'Enter a valid non-negative number.',
      );
      expect(
        await _messageFor(tester, const Locale('ar'), rateFailure),
        'أدخل رقم صحيح غير سالب.',
      );
    });

    testWidgets(
      'localizes atomic trip mutation permission and not-found failures',
      (tester) async {
        const managementFailure = PermissionFailure(
          code: FailureCodes.permissionTripsManagement,
          message: 'raw management message',
        );
        const statusFailure = PermissionFailure(
          code: FailureCodes.permissionTripStatusUpdate,
          message: 'raw status message',
        );
        const notFoundFailure = NotFoundFailure(
          code: TripFailureCodes.notFound,
          message: 'raw not-found message',
        );

        expect(
          await _messageFor(tester, const Locale('en'), managementFailure),
          'Trips management is not allowed for this role.',
        );
        expect(
          await _messageFor(tester, const Locale('ar'), managementFailure),
          'هذا الدور غير مسموح له بإدارة الرحلات.',
        );
        expect(
          await _messageFor(tester, const Locale('en'), statusFailure),
          'Trip status update is not allowed for this role.',
        );
        expect(
          await _messageFor(tester, const Locale('ar'), statusFailure),
          'هذا الدور غير مسموح له بتحديث حالة الرحلة.',
        );
        expect(
          await _messageFor(tester, const Locale('en'), notFoundFailure),
          'The trip could not be found.',
        );
        expect(
          await _messageFor(tester, const Locale('ar'), notFoundFailure),
          'تعذر العثور على الرحلة.',
        );
      },
    );

    testWidgets('localizes status evidence conflict separately from removal', (
      tester,
    ) async {
      const statusEvidenceFailure = ConflictFailure(
        code: TripFailureCodes.conflictStatusEvidenceRequired,
      );

      expect(
        await _messageFor(tester, const Locale('en'), statusEvidenceFailure),
        'Upload an active Waybill or Proof of Delivery before changing the Trip to Documents Received.',
      );
      expect(
        await _messageFor(tester, const Locale('ar'), statusEvidenceFailure),
        'ارفع بوليصة أو إثبات تسليم نشط قبل تغيير حالة الرحلة إلى استلام المستندات.',
      );
    });

    testWidgets(
      'localizes financial readiness and currency mismatch failures',
      (tester) async {
        const readinessFailure = ConflictFailure(
          code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
          message: 'raw readiness message',
        );
        const currencyFailure = ValidationFailure(
          code: TripFailureCodes.financialCurrencyMismatch,
          message: 'raw currency message',
        );

        expect(
          await _messageFor(tester, const Locale('en'), readinessFailure),
          'Configure the company financial settings before using this module.',
        );
        expect(
          await _messageFor(tester, const Locale('ar'), readinessFailure),
          'أكمل الإعدادات المالية للشركة قبل استخدام هذه الوحدة.',
        );
        expect(
          await _messageFor(tester, const Locale('en'), currencyFailure),
          'Financial data currency does not match the company currency.',
        );
        expect(
          await _messageFor(tester, const Locale('ar'), currencyFailure),
          'عملة البيانات المالية لا تطابق عملة الشركة.',
        );
      },
    );
  });
}

Future<String> _messageFor(
  WidgetTester tester,
  Locale locale,
  Failure failure,
) async {
  String? message;

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          message = tripsFailureMessage(context, failure);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return message!;
}
