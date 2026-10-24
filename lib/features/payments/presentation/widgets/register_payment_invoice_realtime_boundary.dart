import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/realtime/domain/entities/company_invalidation_resource.dart';
import '../../../../core/realtime/presentation/widgets/company_resource_invalidation_boundary.dart';
import '../cubit/register_payment_cubit.dart';

/// The payment dialog consumes invoice invalidations from the existing
/// company session, without creating another Realtime subscription.
final class RegisterPaymentInvoiceRealtimeBoundary extends StatelessWidget {
  final String companyId;
  final Widget child;

  const RegisterPaymentInvoiceRealtimeBoundary({
    required this.companyId,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CompanyResourceInvalidationBoundary(
      companyId: companyId,
      resources: const {CompanyInvalidationResource.paymentFormLookups},
      onInvalidate: (context) => context
          .read<RegisterPaymentCubit>()
          .refreshPayableInvoicesFromRealtime(),
      child: child,
    );
  }
}
