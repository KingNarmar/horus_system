import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/presentation/cubit/customers_state.dart';
import 'package:horus_system/features/customers/presentation/dialogs/customer_details_dialog.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  for (final language in ['en', 'ar']) {
    for (final width in [390.0, 1280.0]) {
      testWidgets('renders projected activity in $language at width $width', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 1000);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        const entity = Customer(
          id: 'entity-1',
          companyId: 'company-1',
          name: 'Customer',
        );
        final log = AuditLog(
          id: 'log-1',
          companyId: 'company-1',
          module: AuditModule.customers,
          entityType: AuditEntityType.customer,
          entityId: entity.id,
          action: AuditAction.created,
          description: 'Created',
          createdAt: DateTime.utc(2026, 9, 6, 20, 30),
        );
        final state = CustomersLoaded(
          currentCompanyContext: const CurrentCompanyContext(
            company: Company(
              id: 'company-1',
              name: 'Company',
              businessTimezone: 'Asia/Dubai',
            ),
            role: CompanyRole.owner,
          ),
          allCustomers: const [entity],
          canManageCustomers: true,
          selectedCustomer: entity,
          selectedCustomerActivity: [log],
          selectedCustomerActivityTimestampsByLogId: {
            log.id: BusinessLocalDateTime(
              year: 2026,
              month: 9,
              day: 7,
              hour: 0,
              minute: 30,
            ),
          },
        );
        late String expected;
        late String raw;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                final strings = MaterialLocalizations.of(context);
                expected = strings.formatMediumDate(DateTime.utc(2026, 9, 7));
                raw = strings.formatMediumDate(DateTime.utc(2026, 9, 6));
                return Scaffold(
                  body: CustomerDetailsDialog(customer: entity, state: state),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining(expected), findsWidgets);
        expect(find.textContaining(raw), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
