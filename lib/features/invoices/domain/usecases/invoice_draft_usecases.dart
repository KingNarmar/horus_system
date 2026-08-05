import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/invoice.dart';
import '../entities/invoice_creation_context.dart';
import '../entities/invoice_draft_data.dart';
import '../policies/invoice_lifecycle_policy.dart';
import '../policies/invoices_permission_policy.dart';
import '../repositories/invoices_repository.dart';
import '../services/invoice_draft_factory.dart';
import 'invoice_params.dart';

final class CreateInvoiceFromTripUseCase
    implements UseCase<Invoice, CreateInvoiceFromTripParams> {
  final InvoicesRepository _repository;
  final InvoiceDraftFactory _factory;

  const CreateInvoiceFromTripUseCase(
    this._repository, {
    InvoiceDraftFactory factory = const InvoiceDraftFactory(),
  }) : _factory = factory;

  @override
  Future<Result<Invoice>> call(CreateInvoiceFromTripParams params) {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canManageInvoiceDrafts(context.role)) {
      return Future.value(
        const FailureResult<Invoice>(
          PermissionFailure(code: FailureCodes.permissionInvoicesManagement),
        ),
      );
    }

    if (params.input.tripIds.length != 1) {
      return Future.value(
        const FailureResult<Invoice>(
          ValidationFailure(
            code: FailureCodes.validationInvoiceSingleTripRequired,
          ),
        ),
      );
    }

    return _buildAndPersistDraft(
      repository: _repository,
      factory: _factory,
      input: params.input,
      context: context,
    );
  }
}

final class CreateGroupedInvoiceUseCase
    implements UseCase<Invoice, CreateGroupedInvoiceParams> {
  final InvoicesRepository _repository;
  final InvoiceDraftFactory _factory;

  const CreateGroupedInvoiceUseCase(
    this._repository, {
    InvoiceDraftFactory factory = const InvoiceDraftFactory(),
  }) : _factory = factory;

  @override
  Future<Result<Invoice>> call(CreateGroupedInvoiceParams params) {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canManageInvoiceDrafts(context.role)) {
      return Future.value(
        const FailureResult<Invoice>(
          PermissionFailure(code: FailureCodes.permissionInvoicesManagement),
        ),
      );
    }

    if (params.input.tripIds.length < 2) {
      return Future.value(
        const FailureResult<Invoice>(
          ValidationFailure(
            code: FailureCodes.validationInvoiceGroupedTripsRequired,
          ),
        ),
      );
    }

    return _buildAndPersistDraft(
      repository: _repository,
      factory: _factory,
      input: params.input,
      context: context,
    );
  }
}

final class UpdateInvoiceDraftUseCase
    implements UseCase<Invoice, UpdateInvoiceDraftParams> {
  final InvoicesRepository _repository;
  final InvoiceDraftFactory _factory;

  const UpdateInvoiceDraftUseCase(
    this._repository, {
    InvoiceDraftFactory factory = const InvoiceDraftFactory(),
  }) : _factory = factory;

  @override
  Future<Result<Invoice>> call(UpdateInvoiceDraftParams params) async {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canManageInvoiceDrafts(context.role)) {
      return const FailureResult<Invoice>(
        PermissionFailure(code: FailureCodes.permissionInvoicesManagement),
      );
    }

    final invoiceId = _optional(params.invoiceId);
    if (invoiceId == null) {
      return const FailureResult<Invoice>(
        ValidationFailure(code: FailureCodes.validationInvoiceIdRequired),
      );
    }

    final currentResult = await _repository.getInvoiceDetails(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
    if (currentResult is FailureResult<Invoice>) {
      return FailureResult<Invoice>(currentResult.failure);
    }

    final currentInvoice = (currentResult as Success<Invoice>).data;
    if (!InvoiceLifecyclePolicy.canEdit(currentInvoice.status)) {
      return const FailureResult<Invoice>(
        ConflictFailure(code: FailureCodes.conflictInvoiceIssuedImmutable),
      );
    }

    return _buildAndPersistDraft(
      repository: _repository,
      factory: _factory,
      context: context,
      input: params.input,
      invoiceId: invoiceId,
    );
  }
}

Future<Result<Invoice>> _buildAndPersistDraft({
  required InvoicesRepository repository,
  required InvoiceDraftFactory factory,
  required CurrentCompanyContext context,
  required InvoiceDraftInput input,
  String? invoiceId,
}) async {
  final customerId = _optional(input.customerId);
  if (customerId == null) {
    return const FailureResult<Invoice>(
      ValidationFailure(code: FailureCodes.validationInvoiceCustomerRequired),
    );
  }

  final tripIds = input.tripIds
      .map(_optional)
      .whereType<String>()
      .toList(growable: false);
  if (tripIds.length != input.tripIds.length) {
    return const FailureResult<Invoice>(
      ValidationFailure(code: FailureCodes.validationInvoiceTripsRequired),
    );
  }

  final contextResult = await repository.getCreationContext(
    companyId: context.companyId,
    tripIds: tripIds,
  );
  if (contextResult is FailureResult<InvoiceCreationContext>) {
    return FailureResult<Invoice>(contextResult.failure);
  }

  final dataResult = factory.create(
    companyId: context.companyId,
    customerId: customerId,
    requestedTripIds: tripIds,
    context: (contextResult as Success<InvoiceCreationContext>).data,
    currencyCode: input.currencyCode,
    discountMinorUnits: input.discountMinorUnits,
    taxRateBasisPoints: input.taxRateBasisPoints,
    issueDate: input.issueDate,
    dueDate: input.dueDate,
    notes: input.notes,
  );
  if (dataResult is FailureResult<InvoiceDraftData>) {
    return FailureResult<Invoice>(dataResult.failure);
  }

  final data = (dataResult as Success<InvoiceDraftData>).data;
  if (invoiceId == null) {
    return repository.createInvoiceDraft(
      data: data,
      actorRole: context.role.value,
    );
  }

  return repository.updateInvoiceDraft(
    invoiceId: invoiceId,
    data: data,
    actorRole: context.role.value,
  );
}

String? _optional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
