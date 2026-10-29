import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/app_dependencies.dart';
import '../../features/company/presentation/cubit/company_invitations_cubit.dart';
import '../../features/company/presentation/cubit/company_member_actions_cubit.dart';
import '../../features/company/presentation/cubit/company_users_cubit.dart';
import '../../features/customers/presentation/cubit/customers_cubit.dart';
import '../../features/drivers/presentation/cubit/driver_compensation_cubit.dart';
import '../../features/drivers/presentation/cubit/drivers_cubit.dart';

/// Composition-root ownership for tenant-specific Cubits.
///
/// CompanyContextAccessView keys its protected subtree by company and role.
/// Consequently leaving that subtree closes these Cubits, so old membership,
/// customer and driver state cannot be reused by the next company.
final class CompanyScopedCubitBoundary extends StatelessWidget {
  final Widget child;

  const CompanyScopedCubitBoundary({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CompanyUsersCubit>(
          create: (_) => AppDependencies.createCompanyUsersCubit(),
        ),
        BlocProvider<CompanyInvitationsCubit>(
          create: (_) => AppDependencies.createCompanyInvitationsCubit(),
        ),
        BlocProvider<CompanyMemberActionsCubit>(
          create: (_) => AppDependencies.createCompanyMemberActionsCubit(),
        ),
        BlocProvider<CustomersCubit>(
          create: (_) => AppDependencies.createCustomersCubit(),
        ),
        BlocProvider<DriversCubit>(
          create: (_) => AppDependencies.createDriversCubit(),
        ),
        BlocProvider<DriverCompensationCubit>(
          create: (_) => AppDependencies.createDriverCompensationCubit(),
        ),
      ],
      child: child,
    );
  }
}
