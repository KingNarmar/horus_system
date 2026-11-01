import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/constants/app_icons.dart';
import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/value_objects/business_local_date_time.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
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
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/domain/repositories/customers_repository.dart';
import 'package:horus_system/features/customers/domain/usecases/add_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/can_manage_customers_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/deactivate_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/get_customers_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/reactivate_customer_usecase.dart';
import 'package:horus_system/features/customers/domain/usecases/update_customer_usecase.dart';
import 'package:horus_system/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:horus_system/features/customers/presentation/cubit/customers_state.dart';
import 'package:horus_system/features/customers/presentation/dialogs/customer_details_dialog.dart';
import 'package:horus_system/features/customers/presentation/pages/customers_page.dart';
import 'package:horus_system/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'details dialog uses page-scoped cubit and displays customer audit',
    (tester) async {
      final customersRepository = _CustomersRepository();
      final cubit = CustomersCubit(
        getCustomersUseCase: GetCustomersUseCase(customersRepository),
        canManageCustomersUseCase: const CanManageCustomersUseCase(),
        addCustomerUseCase: AddCustomerUseCase(customersRepository),
        updateCustomerUseCase: UpdateCustomerUseCase(customersRepository),
        deactivateCustomerUseCase: DeactivateCustomerUseCase(
          customersRepository,
        ),
        reactivateCustomerUseCase: ReactivateCustomerUseCase(
          customersRepository,
        ),
        getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
          _AuditLogRepository(),
        ),
        convertInstantsToBusinessLocalDateTimesUseCase:
            const ConvertInstantsToBusinessLocalDateTimesUseCase(
              _BusinessTimeZoneConverter(),
            ),
      );
      addTearDown(cubit.close);

      // Provider is intentionally INSIDE the MaterialApp route. A dialog
      // created by showDialog is pushed onto the Navigator, outside this scope.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<CustomersCubit>.value(
            value: cubit,
            child: const Scaffold(
              body: CustomersPage(currentCompanyContext: _context),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.view), findsOneWidget);
      await tester.tap(find.byIcon(AppIcons.view));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomerDetailsDialog), findsOneWidget);
      final details = find.byType(CustomerDetailsDialog);
      expect(
        find.descendant(of: details, matching: find.text(_customer.name)),
        findsWidgets,
      );
      expect(
        find.descendant(of: details, matching: find.text('QA Operator')),
        findsWidgets,
      );
      expect((cubit.state as CustomersLoaded).selectedCustomer?.id, _customer.id);

      await tester.tap(
        find.descendant(
          of: details,
          matching: find.byIcon(AppIcons.clear),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomerDetailsDialog), findsNothing);
      expect((cubit.state as CustomersLoaded).selectedCustomer, isNull);
    },
  );
}

const _company = Company(
  id: 'test-company',
  name: 'Test Company',
  businessTimezone: 'Asia/Dubai',
);
const _context = CurrentCompanyContext(
  company: _company,
  role: CompanyRole.owner,
);
const _customer = Customer(
  id: 'test-customer',
  companyId: 'test-company',
  name: 'HORUS QA Customer',
  city: 'Dubai',
);

final class _CustomersRepository extends Fake implements CustomersRepository {
  @override
  Future<Result<List<Customer>>> getCustomers({
    required String companyId,
  }) async {
    return const Success(<Customer>[_customer]);
  }
}

final class _AuditLogRepository extends Fake implements AuditLogRepository {
  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return Success(<AuditLog>[
      AuditLog(
        id: 'audit-1',
        companyId: companyId,
        module: module,
        entityType: entityType,
        entityId: entityId,
        action: AuditAction.created,
        description: 'customer.created',
        actorRole: 'owner',
        actorDisplayName: 'QA Operator',
        createdAt: DateTime.utc(2026, 11, 1, 12),
      ),
    ]);
  }
}

final class _BusinessTimeZoneConverter implements BusinessTimeZoneConverter {
  const _BusinessTimeZoneConverter();

  @override
  Result<BusinessLocalDateTime> toBusinessLocalDateTime({
    required DateTime instant,
    required String timeZoneId,
  }) {
    return Success(
      BusinessLocalDateTime(
        year: instant.year,
        month: instant.month,
        day: instant.day,
        hour: instant.hour,
        minute: instant.minute,
      ),
    );
  }

  @override
  Result<DateTime> toUtcInstant({
    required BusinessLocalDateTime localDateTime,
    required String timeZoneId,
  }) {
    return Success(
      DateTime.utc(
        localDateTime.year,
        localDateTime.month,
        localDateTime.day,
        localDateTime.hour,
        localDateTime.minute,
      ),
    );
  }
}
