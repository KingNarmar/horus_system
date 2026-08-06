import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/invoice_lifecycle_usecases.dart';
import '../../domain/usecases/invoice_params.dart';
import '../../domain/usecases/invoice_query_usecases.dart';
import 'invoice_details_state.dart';

final class InvoiceDetailsCubit extends Cubit<InvoiceDetailsState> {
  final GetInvoiceDetailsUseCase getInvoiceDetailsUseCase;
  final IssueInvoiceUseCase issueInvoiceUseCase;
  final CancelInvoiceUseCase cancelInvoiceUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadGeneration = 0;

  InvoiceDetailsCubit({
    required this.getInvoiceDetailsUseCase,
    required this.issueInvoiceUseCase,
    required this.cancelInvoiceUseCase,
    required this.getEntityAuditLogsUseCase,
  }) : super(const InvoiceDetailsInitial());

  Future<void> loadInvoiceDetails({
    required CurrentCompanyContext currentCompanyContext,
    required String invoiceId,
  }) async {
    final generation = ++_loadGeneration;
    _currentCompanyContext = currentCompanyContext;
    emit(const InvoiceDetailsLoading());

    final result = await getInvoiceDetailsUseCase(
      GetInvoiceDetailsParams(
        currentCompanyContext: currentCompanyContext,
        invoiceId: invoiceId,
      ),
    );
    if (!_isCurrentRequest(generation, currentCompanyContext.companyId)) {
      return;
    }

    if (result is FailureResult<Invoice>) {
      emit(InvoiceDetailsFailure(result.failure));
      return;
    }

    final invoice = result.dataOrNull;
    if (invoice == null) return;
    emit(
      InvoiceDetailsLoaded(
        currentCompanyContext: currentCompanyContext,
        invoice: invoice,
        isActivityLoading: true,
      ),
    );
    await _loadActivity(invoice: invoice, generation: generation);
  }

  Future<void> reloadActivity() async {
    final currentState = state;
    if (currentState is! InvoiceDetailsLoaded) return;
    emit(currentState.copyWith(isActivityLoading: true, activityFailure: null));
    await _loadActivity(
      invoice: currentState.invoice,
      generation: _loadGeneration,
    );
  }

  Future<bool> issueInvoice({
    required DateTime issueDate,
    required DateTime dueDate,
  }) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! InvoiceDetailsLoaded ||
        context == null ||
        !currentState.canIssue ||
        currentState.isMutationPending) {
      return false;
    }

    final generation = _loadGeneration;
    final companyId = context.companyId;
    final invoiceId = currentState.invoice.id;
    emit(
      currentState.copyWith(
        pendingAction: InvoiceDetailsAction.issue,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await issueInvoiceUseCase(
      IssueInvoiceParams(
        currentCompanyContext: context,
        invoiceId: invoiceId,
        issueDate: issueDate,
        dueDate: dueDate,
      ),
    );
    return _finishMutation(
      result: result,
      generation: generation,
      companyId: companyId,
      invoiceId: invoiceId,
      expectedAction: InvoiceDetailsAction.issue,
      feedback: InvoiceDetailsFeedback.issued,
    );
  }

  Future<bool> cancelInvoice({required String reason}) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! InvoiceDetailsLoaded ||
        context == null ||
        !currentState.canCancel ||
        currentState.isMutationPending) {
      return false;
    }

    final generation = _loadGeneration;
    final companyId = context.companyId;
    final invoiceId = currentState.invoice.id;
    emit(
      currentState.copyWith(
        pendingAction: InvoiceDetailsAction.cancel,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await cancelInvoiceUseCase(
      CancelInvoiceParams(
        currentCompanyContext: context,
        invoiceId: invoiceId,
        reason: reason,
      ),
    );
    return _finishMutation(
      result: result,
      generation: generation,
      companyId: companyId,
      invoiceId: invoiceId,
      expectedAction: InvoiceDetailsAction.cancel,
      feedback: InvoiceDetailsFeedback.cancelled,
    );
  }

  void clearFeedback() {
    final currentState = state;
    if (currentState is InvoiceDetailsLoaded) {
      emit(currentState.copyWith(mutationFailure: null, feedback: null));
    }
  }

  Future<void> _loadActivity({
    required Invoice invoice,
    required int generation,
  }) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final result = await getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context.companyId,
        module: AuditModule.invoices,
        entityType: AuditEntityType.invoice,
        entityId: invoice.id,
      ),
    );

    final latestState = state;
    if (!_isCurrentRequest(generation, context.companyId) ||
        latestState is! InvoiceDetailsLoaded ||
        latestState.invoice.id != invoice.id) {
      return;
    }

    result.when(
      success: (logs) => emit(
        latestState.copyWith(
          activity: logs,
          isActivityLoading: false,
          activityFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      ),
    );
  }

  Future<bool> _finishMutation({
    required Result<Invoice> result,
    required int generation,
    required String companyId,
    required String invoiceId,
    required InvoiceDetailsAction expectedAction,
    required InvoiceDetailsFeedback feedback,
  }) async {
    final latestState = state;
    if (!_isCurrentRequest(generation, companyId) ||
        latestState is! InvoiceDetailsLoaded ||
        latestState.invoice.id != invoiceId ||
        latestState.pendingAction != expectedAction) {
      return false;
    }

    if (result is FailureResult<Invoice>) {
      emit(
        latestState.copyWith(
          pendingAction: null,
          mutationFailure: result.failure,
        ),
      );
      return false;
    }

    final invoice = result.dataOrNull;
    if (invoice == null) {
      emit(latestState.copyWith(pendingAction: null));
      return false;
    }

    emit(
      latestState.copyWith(
        invoice: invoice,
        pendingAction: null,
        mutationFailure: null,
        feedback: feedback,
        isActivityLoading: true,
        activityFailure: null,
      ),
    );
    await _loadActivity(invoice: invoice, generation: generation);
    return true;
  }

  bool _isCurrentRequest(int generation, String companyId) {
    return generation == _loadGeneration &&
        _currentCompanyContext?.companyId == companyId;
  }
}
