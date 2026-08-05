import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/billable_trip.dart';
import '../entities/invoice.dart';
import '../policies/invoices_permission_policy.dart';
import '../repositories/invoices_repository.dart';
import 'invoice_params.dart';

final class GetInvoicesUseCase
    implements UseCase<List<Invoice>, GetInvoicesParams> {
  final InvoicesRepository _repository;

  const GetInvoicesUseCase(this._repository);

  @override
  Future<Result<List<Invoice>>> call(GetInvoicesParams params) {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canViewInvoices(context.role)) {
      return Future.value(
        const FailureResult<List<Invoice>>(
          PermissionFailure(code: FailureCodes.permissionInvoicesView),
        ),
      );
    }

    return _repository.getInvoices(companyId: context.companyId);
  }
}

final class GetInvoiceDetailsUseCase
    implements UseCase<Invoice, GetInvoiceDetailsParams> {
  final InvoicesRepository _repository;

  const GetInvoiceDetailsUseCase(this._repository);

  @override
  Future<Result<Invoice>> call(GetInvoiceDetailsParams params) {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canViewInvoices(context.role)) {
      return Future.value(
        const FailureResult<Invoice>(
          PermissionFailure(code: FailureCodes.permissionInvoicesView),
        ),
      );
    }

    final invoiceId = _optional(params.invoiceId);
    if (invoiceId == null) {
      return Future.value(
        const FailureResult<Invoice>(
          ValidationFailure(code: FailureCodes.validationInvoiceIdRequired),
        ),
      );
    }

    return _repository.getInvoiceDetails(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
  }
}

final class GetBillableTripsUseCase
    implements UseCase<List<BillableTrip>, GetBillableTripsParams> {
  final InvoicesRepository _repository;

  const GetBillableTripsUseCase(this._repository);

  @override
  Future<Result<List<BillableTrip>>> call(GetBillableTripsParams params) {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canManageInvoiceDrafts(context.role)) {
      return Future.value(
        const FailureResult<List<BillableTrip>>(
          PermissionFailure(code: FailureCodes.permissionInvoicesManagement),
        ),
      );
    }

    return _repository.getBillableTrips(
      companyId: context.companyId,
      customerId: _optional(params.customerId),
    );
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
