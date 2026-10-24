import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_totals.dart';
import '../../domain/entities/invoice_status.dart';
import '../../domain/usecases/calculate_invoice_draft_preview_usecase.dart';
import '../../domain/usecases/can_manage_invoice_drafts_usecase.dart';
import '../../domain/usecases/invoice_draft_usecases.dart';
import '../../domain/usecases/invoice_params.dart';
import '../../domain/usecases/invoice_query_usecases.dart';
import 'invoice_draft_form_input.dart';
import 'invoices_state.dart';

final class InvoicesCubit extends Cubit<InvoicesState> {
  final GetInvoicesUseCase getInvoicesUseCase;
  final CanManageInvoiceDraftsUseCase canManageInvoiceDraftsUseCase;
  final GetBillableTripsUseCase getBillableTripsUseCase;
  final CalculateInvoiceDraftPreviewUseCase calculateInvoiceDraftPreviewUseCase;
  final CreateInvoiceFromTripUseCase createInvoiceFromTripUseCase;
  final CreateGroupedInvoiceUseCase createGroupedInvoiceUseCase;
  final UpdateInvoiceDraftUseCase updateInvoiceDraftUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadGeneration = 0;
  int _billableTripsGeneration = 0;
  int _invoiceMutationRevision = 0;
  bool _invoicesRefreshInProgress = false;
  bool _invoicesRefreshPending = false;
  bool _billableTripsRefreshInProgress = false;
  bool _billableTripsRefreshPending = false;

  InvoicesCubit({
    required this.getInvoicesUseCase,
    required this.canManageInvoiceDraftsUseCase,
    required this.getBillableTripsUseCase,
    required this.calculateInvoiceDraftPreviewUseCase,
    required this.createInvoiceFromTripUseCase,
    required this.createGroupedInvoiceUseCase,
    required this.updateInvoiceDraftUseCase,
  }) : super(const InvoicesInitial());

  Future<void> loadInvoices(CurrentCompanyContext currentCompanyContext) async {
    final generation = ++_loadGeneration;
    _billableTripsGeneration++;
    _currentCompanyContext = currentCompanyContext;

    final previousState = state;
    final previousLoadedState =
        previousState is InvoicesLoaded &&
            previousState.currentCompanyContext.companyId ==
                currentCompanyContext.companyId
        ? previousState
        : null;
    final previousSearch = previousLoadedState?.searchQuery ?? '';
    final previousStatus = previousLoadedState?.statusFilter;

    emit(const InvoicesLoading());

    final result = await getInvoicesUseCase(
      GetInvoicesParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentLoad(generation, currentCompanyContext.companyId)) return;

    if (result is FailureResult<List<Invoice>>) {
      emit(InvoicesFailure(result.failure));
      return;
    }

    final permissionResult = await canManageInvoiceDraftsUseCase(
      CanManageInvoiceDraftsParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentLoad(generation, currentCompanyContext.companyId)) return;

    final permissionFailure = permissionResult.failureOrNull;
    if (permissionFailure != null) {
      emit(InvoicesFailure(permissionFailure));
      return;
    }

    final canManageInvoiceDrafts = permissionResult.dataOrNull ?? false;
    emit(
      InvoicesLoaded(
        currentCompanyContext: currentCompanyContext,
        allInvoices: result.dataOrNull ?? const [],
        billableTrips: const [],
        canManageInvoiceDrafts: canManageInvoiceDrafts,
        searchQuery: previousSearch,
        statusFilter: previousStatus,
      ),
    );

    if (canManageInvoiceDrafts) {
      await loadBillableTrips();
    }
    if (_invoicesRefreshPending) {
      unawaited(refreshInvoicesFromRealtime());
    }
    if (_billableTripsRefreshPending) {
      unawaited(refreshBillableTripsFromRealtime());
    }
  }

  Future<void> refresh() async {
    final context = _currentCompanyContext;
    if (context == null) return;
    if (state is InvoicesLoaded) {
      await refreshInvoicesFromRealtime();
      await refreshBillableTripsFromRealtime();
    } else {
      await loadInvoices(context);
    }
  }

  /// Refresh server truth without clearing filters, feedback or pending forms.
  /// Coalesce duplicate events and replay a signal after a concurrent write.
  Future<void> refreshInvoicesFromRealtime() async {
    _invoicesRefreshPending = true;
    if (_invoicesRefreshInProgress) return;
    _invoicesRefreshInProgress = true;
    try {
      while (_invoicesRefreshPending && !isClosed) {
        _invoicesRefreshPending = false;
        final current = state;
        final context = _currentCompanyContext;
        if (current is! InvoicesLoaded ||
            context == null ||
            current.isCreatingDraft ||
            current.pendingDraftInvoiceId != null) {
          _invoicesRefreshPending = true;
          break;
        }
        final generation = _loadGeneration;
        final mutationRevision = _invoiceMutationRevision;
        final result = await getInvoicesUseCase(
          GetInvoicesParams(currentCompanyContext: context),
        );
        if (!_isCurrentLoad(generation, context.companyId)) return;
        final latest = state;
        if (latest is! InvoicesLoaded) {
          _invoicesRefreshPending = true;
          break;
        }
        if (mutationRevision != _invoiceMutationRevision ||
            latest.isCreatingDraft ||
            latest.pendingDraftInvoiceId != null) {
          _invoicesRefreshPending = true;
          break;
        }
        final failure = result.failureOrNull;
        if (failure != null) {
          emit(latest.copyWith(realtimeRefreshFailure: failure));
        } else {
          emit(
            latest.copyWith(
              allInvoices: List.unmodifiable(result.dataOrNull ?? const <Invoice>[]),
              realtimeRefreshFailure: null,
            ),
          );
        }
      }
    } finally {
      _invoicesRefreshInProgress = false;
    }
  }

  /// Billable-trip reservations change even when invoice.status stays draft.
  Future<void> refreshBillableTripsFromRealtime() async {
    _billableTripsRefreshPending = true;
    if (_billableTripsRefreshInProgress) return;
    _billableTripsRefreshInProgress = true;
    try {
      while (_billableTripsRefreshPending && !isClosed) {
        _billableTripsRefreshPending = false;
        final current = state;
        final context = _currentCompanyContext;
        if (current is! InvoicesLoaded || context == null) {
          _billableTripsRefreshPending = true;
          break;
        }
        if (!current.canManageInvoiceDrafts) break;
        final generation = ++_billableTripsGeneration;
        final result = await getBillableTripsUseCase(
          GetBillableTripsParams(currentCompanyContext: context),
        );
        if (isClosed || generation != _billableTripsGeneration) {
          _billableTripsRefreshPending = true;
          break;
        }
        final latest = state;
        if (latest is! InvoicesLoaded ||
            latest.currentCompanyContext.companyId != context.companyId) {
          _billableTripsRefreshPending = true;
          break;
        }
        final failure = result.failureOrNull;
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
      _billableTripsRefreshInProgress = false;
    }
  }

  Future<void> loadBillableTrips({String? customerId}) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! InvoicesLoaded ||
        context == null ||
        !currentState.canManageInvoiceDrafts) {
      return;
    }

    final generation = ++_billableTripsGeneration;
    final companyId = context.companyId;
    emit(
      currentState.copyWith(
        isBillableTripsLoading: true,
        billableTripsFailure: null,
      ),
    );

    final result = await getBillableTripsUseCase(
      GetBillableTripsParams(
        currentCompanyContext: context,
        customerId: customerId,
      ),
    );

    final latestState = state;
    if (generation != _billableTripsGeneration ||
        latestState is! InvoicesLoaded ||
        latestState.currentCompanyContext.companyId != companyId) {
      return;
    }

    result.when(
      success: (trips) => emit(
        latestState.copyWith(
          billableTrips: trips,
          isBillableTripsLoading: false,
          billableTripsFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          isBillableTripsLoading: false,
          billableTripsFailure: failure,
        ),
      ),
    );
  }

  void setSearchQuery(String value) {
    final currentState = state;
    if (currentState is InvoicesLoaded) {
      emit(currentState.copyWith(searchQuery: value));
    }
  }

  void setStatusFilter(InvoiceStatus? status) {
    final currentState = state;
    if (currentState is InvoicesLoaded) {
      emit(currentState.copyWith(statusFilter: status));
    }
  }

  Future<InvoiceTotals?> calculateDraftPreview({
    required String customerId,
    required List<BillableTrip> trips,
  }) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! InvoicesLoaded ||
        context == null ||
        !currentState.canManageInvoiceDrafts) {
      return null;
    }

    final companyId = context.companyId;
    final contextGeneration = _loadGeneration;
    final result = await calculateInvoiceDraftPreviewUseCase(
      CalculateInvoiceDraftPreviewParams(
        currentCompanyContext: context,
        customerId: customerId,
        trips: trips,
      ),
    );

    final latestState = state;
    if (contextGeneration != _loadGeneration ||
        latestState is! InvoicesLoaded ||
        latestState.currentCompanyContext.companyId != companyId) {
      return null;
    }

    if (result is FailureResult<InvoiceTotals>) {
      emit(latestState.copyWith(mutationFailure: result.failure));
      return null;
    }
    if (latestState.mutationFailure != null) {
      emit(latestState.copyWith(mutationFailure: null));
    }
    return result.dataOrNull;
  }

  Future<bool> createDraft(InvoiceDraftFormInput input) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! InvoicesLoaded ||
        context == null ||
        !currentState.canManageInvoiceDrafts ||
        currentState.isCreatingDraft ||
        currentState.pendingDraftInvoiceId != null) {
      return false;
    }

    final companyId = context.companyId;
    final contextGeneration = _loadGeneration;
    ++_invoiceMutationRevision;
    emit(
      currentState.copyWith(
        isCreatingDraft: true,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = input.tripIds.length == 1
        ? await createInvoiceFromTripUseCase(
            input.toCreateFromTripParams(context),
          )
        : await createGroupedInvoiceUseCase(
            CreateGroupedInvoiceParams(
              currentCompanyContext: context,
              input: input.toDomainInput(),
            ),
          );

    final latestState = state;
    if (contextGeneration != _loadGeneration ||
        latestState is! InvoicesLoaded ||
        latestState.currentCompanyContext.companyId != companyId) {
      return false;
    }

    if (result is FailureResult<Invoice>) {
      emit(
        latestState.copyWith(
          isCreatingDraft: false,
          mutationFailure: result.failure,
        ),
      );
      _drainRealtimeRefreshes();
      return false;
    }

    final invoice = result.dataOrNull;
    if (invoice == null) {
      emit(latestState.copyWith(isCreatingDraft: false));
      return false;
    }

    ++_invoiceMutationRevision;
    emit(
      _upsertInvoice(latestState, invoice).copyWith(
        isCreatingDraft: false,
        mutationFailure: null,
        feedback: InvoiceListFeedback.draftCreated,
      ),
    );
    _drainRealtimeRefreshes();
    return true;
  }

  Future<bool> updateDraft({
    required String invoiceId,
    required InvoiceDraftFormInput input,
  }) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! InvoicesLoaded ||
        context == null ||
        !currentState.canManageInvoiceDrafts ||
        currentState.isCreatingDraft ||
        currentState.pendingDraftInvoiceId != null) {
      return false;
    }

    final companyId = context.companyId;
    final contextGeneration = _loadGeneration;
    ++_invoiceMutationRevision;
    emit(
      currentState.copyWith(
        pendingDraftInvoiceId: invoiceId,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await updateInvoiceDraftUseCase(
      input.toUpdateParams(
        currentCompanyContext: context,
        invoiceId: invoiceId,
      ),
    );

    final latestState = state;
    if (contextGeneration != _loadGeneration ||
        latestState is! InvoicesLoaded ||
        latestState.currentCompanyContext.companyId != companyId ||
        latestState.pendingDraftInvoiceId != invoiceId) {
      return false;
    }

    if (result is FailureResult<Invoice>) {
      emit(
        latestState.copyWith(
          pendingDraftInvoiceId: null,
          mutationFailure: result.failure,
        ),
      );
      _drainRealtimeRefreshes();
      return false;
    }

    final invoice = result.dataOrNull;
    if (invoice == null) {
      emit(latestState.copyWith(pendingDraftInvoiceId: null));
      return false;
    }

    ++_invoiceMutationRevision;
    emit(
      _upsertInvoice(latestState, invoice).copyWith(
        pendingDraftInvoiceId: null,
        mutationFailure: null,
        feedback: InvoiceListFeedback.draftUpdated,
      ),
    );
    _drainRealtimeRefreshes();
    return true;
  }

  void clearFeedback() {
    final currentState = state;
    if (currentState is InvoicesLoaded) {
      emit(currentState.copyWith(mutationFailure: null, feedback: null));
    }
  }

  void _drainRealtimeRefreshes() {
    if (_invoicesRefreshPending) {
      unawaited(refreshInvoicesFromRealtime());
    }
    if (_billableTripsRefreshPending) {
      unawaited(refreshBillableTripsFromRealtime());
    }
  }

  bool _isCurrentLoad(int generation, String companyId) {
    return !isClosed && generation == _loadGeneration &&
        _currentCompanyContext?.companyId == companyId;
  }

  InvoicesLoaded _upsertInvoice(InvoicesLoaded currentState, Invoice invoice) {
    final exists = currentState.allInvoices.any(
      (item) => item.id == invoice.id,
    );
    final invoices = exists
        ? currentState.allInvoices
              .map((item) => item.id == invoice.id ? invoice : item)
              .toList(growable: false)
        : [invoice, ...currentState.allInvoices];
    return currentState.copyWith(allInvoices: invoices);
  }
}
