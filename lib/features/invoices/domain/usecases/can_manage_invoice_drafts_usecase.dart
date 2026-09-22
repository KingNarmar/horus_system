import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../policies/invoices_permission_policy.dart';

class CanManageInvoiceDraftsParams {
  final CurrentCompanyContext currentCompanyContext;

  const CanManageInvoiceDraftsParams({required this.currentCompanyContext});
}

class CanManageInvoiceDraftsUseCase
    implements UseCase<bool, CanManageInvoiceDraftsParams> {
  const CanManageInvoiceDraftsUseCase();

  @override
  Future<Result<bool>> call(CanManageInvoiceDraftsParams params) {
    return Future.value(
      Success<bool>(
        InvoicesPermissionPolicy.canManageInvoiceDrafts(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}
