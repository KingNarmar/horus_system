import 'package:flutter/widgets.dart';

import '../core/realtime/presentation/cubit/company_realtime_cubit.dart';
import '../features/app_shell/presentation/widgets/company_realtime_session_boundary.dart';
import '../features/company/domain/entities/current_company_context.dart';

/// Owns the company Realtime session above the Navigator, not per shell route.
///
/// Keying the entire protected navigation subtree also discards all routes and
/// company-owned UI from the former tenant when identity, company or role
/// changes. An unchanged membership revalidation retains the same subtree.
final class AppCompanyRealtimeScope extends StatelessWidget {
  final CurrentCompanyContext? companyContext;
  final String? userId;
  final Widget child;
  final CompanyRealtimeCubit Function()? realtimeCubitFactory;

  const AppCompanyRealtimeScope({
    required this.companyContext,
    required this.userId,
    required this.child,
    this.realtimeCubitFactory,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final activeContext = userId == null ? null : companyContext;

    return KeyedSubtree(
      key: ValueKey((activeContext?.companyId, activeContext?.role, userId)),
      child: activeContext == null
          ? child
          : CompanyRealtimeSessionBoundary(
              companyId: activeContext.companyId,
              role: activeContext.role,
              userId: userId,
              realtimeCubitFactory: realtimeCubitFactory,
              child: child,
            ),
    );
  }
}
