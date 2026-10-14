import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/realtime/di/realtime_dependencies.dart';
import '../../../../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../customers/domain/policies/customers_permission_policy.dart';

/// Owns the single R2 Realtime stream for an authenticated company session.
///
/// For now the only enabled server topic is Customers. Other roles must not
/// subscribe to it, even while navigating through the shell.
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
    if (!CustomersPermissionPolicy.canViewCustomers(role)) return child;

    return BlocProvider<CompanyRealtimeCubit>(
      key: ValueKey((companyId, role, userId)),
      create: (_) =>
          (realtimeCubitFactory ?? RealtimeDependencies.createCubit)()
            ..watchCompany(companyId),
      child: child,
    );
  }
}
