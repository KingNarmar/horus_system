import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/realtime/di/realtime_dependencies.dart';
import '../../../../core/realtime/domain/entities/company_data_change.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company_expenses/domain/policies/company_expenses_permission_policy.dart';
import '../../../customers/domain/policies/customers_permission_policy.dart';
import '../../../driver_finance/domain/policies/driver_finance_permission_policy.dart';
import '../../../driver_settlements/domain/policies/driver_settlements_permission_policy.dart';
import '../../../drivers/domain/policies/drivers_permission_policy.dart';
import '../../../fleet/domain/policies/fleet_permission_policy.dart';
import '../../../invoices/domain/policies/invoices_permission_policy.dart';
import '../../../payments/domain/policies/payments_permission_policy.dart';
import '../../../routes/domain/policies/routes_permission_policy.dart';
import '../../../trips/domain/policies/trips_permission_policy.dart';

/// Owns the single R2 Realtime stream for an authenticated company session.
///
/// Customers, Drivers and Fleet private topics share this single session.
/// Company, user and role changes dispose the previous subscriptions.
final class CompanyRealtimeSessionBoundary extends StatelessWidget {
  final String companyId;
  final CompanyRole role;
  final String? userId;
  final Widget child;
  final CompanyRealtimeCubit Function()? realtimeCubitFactory;

  const CompanyRealtimeSessionBoundary({
    required this.companyId,
    required this.role,
    required this.userId,
    required this.child,
    this.realtimeCubitFactory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!CustomersPermissionPolicy.canViewCustomers(role) &&
        !DriversPermissionPolicy.canViewDrivers(role) &&
        !FleetPermissionPolicy.canViewFleet(role) &&
        !RoutesPermissionPolicy.canViewRoutes(role) &&
        !TripsPermissionPolicy.canViewTrips(role) &&
        !DriverFinancePermissionPolicy.canViewDriverFinance(role) &&
        !DriverSettlementsPermissionPolicy.canViewDriverSettlements(role) &&
        !CompanyExpensesPermissionPolicy.canViewCompanyExpenses(role) &&
        !InvoicesPermissionPolicy.canViewInvoices(role) &&
        !PaymentsPermissionPolicy.canViewPayments(role)) {
      return child;
    }

    return BlocProvider<CompanyRealtimeCubit>(
      key: ValueKey((companyId, role, userId)),
      create: (_) =>
          (realtimeCubitFactory ?? RealtimeDependencies.createCubit)()
            ..watchCompany(
              companyId,
              additionalResources: {
                if (TripsPermissionPolicy.canViewTripFinancials(role)) ...{
                  CompanyDataResource.expenseLedger,
                  CompanyDataResource.tripExpenses,
                },
                if (DriverFinancePermissionPolicy.canViewDriverFinance(role))
                  CompanyDataResource.driverFinance,
                if (DriverSettlementsPermissionPolicy.canViewDriverSettlements(
                  role,
                ))
                  CompanyDataResource.driverSettlements,
                if (CompanyExpensesPermissionPolicy.canViewCompanyExpenses(
                  role,
                ))
                  CompanyDataResource.companyExpenses,
                if (InvoicesPermissionPolicy.canViewInvoices(role))
                  CompanyDataResource.invoices,
                if (PaymentsPermissionPolicy.canViewPayments(role))
                  CompanyDataResource.payments,
              },
            ),
      child: child,
    );
  }
}
