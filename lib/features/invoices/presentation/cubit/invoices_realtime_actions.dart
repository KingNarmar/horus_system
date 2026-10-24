part of 'invoices_cubit.dart';

/// Invoice-specific, non-destructive reconciliation driven by the shared
/// company-scoped Realtime session. No socket or backend access lives here.
mixin InvoicesRealtimeActions on Cubit<InvoicesState> {
  /// Refresh server truth without clearing filters, feedback or pending forms.
  /// Coalesce duplicate events and replay a signal after a concurrent write.
  Future<void> refreshInvoicesFromRealtime() async {
    final owner = this as InvoicesCubit;
    owner._invoicesRefreshPending = true;
    if (owner._invoicesRefreshInProgress) return;
    owner._invoicesRefreshInProgress = true;
    try {
      while (owner._invoicesRefreshPending && !isClosed) {
        owner._invoicesRefreshPending = false;
        final current = state;
        final context = owner._currentCompanyContext;
        if (current is! InvoicesLoaded ||
            context == null ||
            current.isCreatingDraft ||
            current.pendingDraftInvoiceId != null) {
          owner._invoicesRefreshPending = true;
          break;
        }
        final generation = owner._loadGeneration;
        final mutationRevision = owner._invoiceMutationRevision;
        final result = await owner.getInvoicesUseCase(
          GetInvoicesParams(currentCompanyContext: context),
        );
        if (!owner._isCurrentLoad(generation, context.companyId)) return;
        final latest = state;
        if (latest is! InvoicesLoaded) {
          owner._invoicesRefreshPending = true;
          break;
        }
        if (mutationRevision != owner._invoiceMutationRevision ||
            latest.isCreatingDraft ||
            latest.pendingDraftInvoiceId != null) {
          owner._invoicesRefreshPending = true;
          break;
        }
        final failure = result.failureOrNull;
        if (failure != null &&
            (failure is AuthFailure || failure is PermissionFailure)) {
          emit(InvoicesFailure(failure));
        } else if (failure != null) {
          emit(latest.copyWith(realtimeRefreshFailure: failure));
        } else {
          emit(
            latest.copyWith(
              allInvoices: List.unmodifiable(
                result.dataOrNull ?? const <Invoice>[],
              ),
              realtimeRefreshFailure: null,
            ),
          );
        }
      }
    } finally {
      owner._invoicesRefreshInProgress = false;
      final current = state;
      if (owner._invoicesRefreshPending &&
          current is InvoicesLoaded &&
          !current.isCreatingDraft &&
          current.pendingDraftInvoiceId == null) {
        unawaited(refreshInvoicesFromRealtime());
      }
    }
  }

  /// Billable-trip reservations change even when invoice.status stays draft.
  Future<void> refreshBillableTripsFromRealtime() async {
    final owner = this as InvoicesCubit;
    owner._billableTripsRefreshPending = true;
    if (owner._billableTripsRefreshInProgress) return;
    owner._billableTripsRefreshInProgress = true;
    try {
      while (owner._billableTripsRefreshPending && !isClosed) {
        owner._billableTripsRefreshPending = false;
        final current = state;
        final context = owner._currentCompanyContext;
        if (current is! InvoicesLoaded || context == null) {
          owner._billableTripsRefreshPending = true;
          break;
        }
        if (!current.canManageInvoiceDrafts) break;
        final generation = ++owner._billableTripsGeneration;
        final result = await owner.getBillableTripsUseCase(
          GetBillableTripsParams(currentCompanyContext: context),
        );
        if (isClosed || generation != owner._billableTripsGeneration) {
          owner._billableTripsRefreshPending = true;
          break;
        }
        final latest = state;
        if (latest is! InvoicesLoaded ||
            latest.currentCompanyContext.companyId != context.companyId) {
          owner._billableTripsRefreshPending = true;
          break;
        }
        final failure = result.failureOrNull;
        if (failure != null &&
            (failure is AuthFailure || failure is PermissionFailure)) {
          emit(InvoicesFailure(failure));
          break;
        }
        emit(
          latest.copyWith(
            billableTrips: failure == null
                ? List.unmodifiable(result.dataOrNull ?? const <BillableTrip>[])
                : null,
            billableTripsFailure: failure,
          ),
        );
      }
    } finally {
      owner._billableTripsRefreshInProgress = false;
      final current = state;
      if (owner._billableTripsRefreshPending &&
          current is InvoicesLoaded &&
          !current.isBillableTripsLoading) {
        unawaited(refreshBillableTripsFromRealtime());
      }
    }
  }
}
