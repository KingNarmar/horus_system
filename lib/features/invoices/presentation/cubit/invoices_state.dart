import '../../../../core/errors/failure.dart';
import '../../../../core/utils/search_text_normalizer.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_status.dart';

const Object _notSet = Object();

enum InvoiceListFeedback { draftCreated, draftUpdated }

sealed class InvoicesState {
  const InvoicesState();
}

final class InvoicesInitial extends InvoicesState {
  const InvoicesInitial();
}

final class InvoicesLoading extends InvoicesState {
  const InvoicesLoading();
}

final class InvoicesLoaded extends InvoicesState {
  final CurrentCompanyContext currentCompanyContext;
  final List<Invoice> allInvoices;
  final List<BillableTrip> billableTrips;
  final bool canManageInvoiceDrafts;
  final String searchQuery;
  final InvoiceStatus? statusFilter;
  final bool isBillableTripsLoading;
  final Failure? billableTripsFailure;
  final bool isCreatingDraft;
  final String? pendingDraftInvoiceId;
  final Failure? mutationFailure;
  final InvoiceListFeedback? feedback;

  const InvoicesLoaded({
    required this.currentCompanyContext,
    required this.allInvoices,
    required this.billableTrips,
    required this.canManageInvoiceDrafts,
    this.searchQuery = '',
    this.statusFilter,
    this.isBillableTripsLoading = false,
    this.billableTripsFailure,
    this.isCreatingDraft = false,
    this.pendingDraftInvoiceId,
    this.mutationFailure,
    this.feedback,
  });

  List<Invoice> get invoices => filteredInvoices();

  List<Invoice> filteredInvoices({
    Map<InvoiceStatus, Iterable<String>> statusSearchTerms = const {},
  }) {
    final normalizedSearch = normalizeSearchText(searchQuery);
    return allInvoices
        .where((invoice) {
          if (statusFilter != null && invoice.status != statusFilter) {
            return false;
          }
          if (normalizedSearch.isEmpty) return true;

          final searchTerms = <Object?>[
            invoice.number?.value,
            invoice.customer.name,
            invoice.customer.taxRegistrationNumber,
            invoice.status.value,
            ...(statusSearchTerms[invoice.status] ?? const <String>[]),
            invoice.issueDate?.value.toIso8601String(),
            invoice.dueDate?.value.toIso8601String(),
            invoice.currency.value,
            invoice.totals.grandTotal.minorUnits,
            invoice.notes,
          ];

          return searchTerms.any((term) {
            if (term == null) return false;
            return normalizeSearchText(
              term.toString(),
            ).contains(normalizedSearch);
          });
        })
        .toList(growable: false);
  }

  BillableTrip? billableTripById(String tripId) {
    for (final trip in billableTrips) {
      if (trip.id == tripId) return trip;
    }
    return null;
  }

  bool isUpdatingDraft(String invoiceId) {
    return pendingDraftInvoiceId == invoiceId;
  }

  InvoicesLoaded copyWith({
    List<Invoice>? allInvoices,
    List<BillableTrip>? billableTrips,
    bool? canManageInvoiceDrafts,
    String? searchQuery,
    Object? statusFilter = _notSet,
    bool? isBillableTripsLoading,
    Object? billableTripsFailure = _notSet,
    bool? isCreatingDraft,
    Object? pendingDraftInvoiceId = _notSet,
    Object? mutationFailure = _notSet,
    Object? feedback = _notSet,
  }) {
    return InvoicesLoaded(
      currentCompanyContext: currentCompanyContext,
      allInvoices: allInvoices ?? this.allInvoices,
      billableTrips: billableTrips ?? this.billableTrips,
      canManageInvoiceDrafts:
          canManageInvoiceDrafts ?? this.canManageInvoiceDrafts,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter == _notSet
          ? this.statusFilter
          : statusFilter as InvoiceStatus?,
      isBillableTripsLoading:
          isBillableTripsLoading ?? this.isBillableTripsLoading,
      billableTripsFailure: billableTripsFailure == _notSet
          ? this.billableTripsFailure
          : billableTripsFailure as Failure?,
      isCreatingDraft: isCreatingDraft ?? this.isCreatingDraft,
      pendingDraftInvoiceId: pendingDraftInvoiceId == _notSet
          ? this.pendingDraftInvoiceId
          : pendingDraftInvoiceId as String?,
      mutationFailure: mutationFailure == _notSet
          ? this.mutationFailure
          : mutationFailure as Failure?,
      feedback: feedback == _notSet
          ? this.feedback
          : feedback as InvoiceListFeedback?,
    );
  }
}

final class InvoicesFailure extends InvoicesState {
  final Failure failure;

  const InvoicesFailure(this.failure);
}
