import '../../../../core/errors/failure.dart';
import '../../../../core/utils/search_text_normalizer.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_driver_option.dart';
import '../../domain/entities/driver_settlement_preview.dart';
import '../../domain/entities/driver_settlement_status.dart';

const Object _notSet = Object();

enum DriverSettlementFeedback { draftCreated, finalized, voided }

sealed class DriverSettlementsState {
  const DriverSettlementsState();
}

class DriverSettlementsInitial extends DriverSettlementsState {
  const DriverSettlementsInitial();
}

class DriverSettlementsLoading extends DriverSettlementsState {
  const DriverSettlementsLoading();
}

class DriverSettlementsLoaded extends DriverSettlementsState {
  final CurrentCompanyContext currentCompanyContext;
  final List<DriverSettlement> allSettlements;
  final List<DriverSettlementDriverOption> driverOptions;
  final bool canManageDriverSettlements;
  final String searchQuery;
  final String? driverIdFilter;
  final DriverSettlementStatus? statusFilter;
  final bool includeVoided;
  final String? pendingActionSettlementId;
  final bool isPreviewLoading;
  final DriverSettlementPreview? preview;
  final Failure? previewFailure;
  final bool isCreatingDraft;
  final DriverSettlement? selectedSettlement;
  final bool isDetailsLoading;
  final Failure? detailsFailure;
  final List<AuditLog> selectedSettlementActivity;
  final bool isActivityLoading;
  final Failure? activityFailure;
  final Failure? mutationFailure;
  final DriverSettlementFeedback? feedback;

  const DriverSettlementsLoaded({
    required this.currentCompanyContext,
    required this.allSettlements,
    required this.driverOptions,
    required this.canManageDriverSettlements,
    this.searchQuery = '',
    this.driverIdFilter,
    this.statusFilter,
    this.includeVoided = false,
    this.pendingActionSettlementId,
    this.isPreviewLoading = false,
    this.preview,
    this.previewFailure,
    this.isCreatingDraft = false,
    this.selectedSettlement,
    this.isDetailsLoading = false,
    this.detailsFailure,
    this.selectedSettlementActivity = const [],
    this.isActivityLoading = false,
    this.activityFailure,
    this.mutationFailure,
    this.feedback,
  });

  List<DriverSettlementDriverOption> get activeDriverOptions => driverOptions
      .where((option) => option.isActive)
      .toList(growable: false);

  String? driverLabel(String driverId) {
    for (final option in driverOptions) {
      if (option.id == driverId) return option.displayName;
    }
    return null;
  }

  List<DriverSettlement> get settlements => filteredSettlements();

  List<DriverSettlement> filteredSettlements({
    Map<DriverSettlementStatus, Iterable<String>> statusSearchTerms = const {},
  }) {
    final normalizedSearch = normalizeSearchText(searchQuery);
    return allSettlements.where((settlement) {
      if (!includeVoided && settlement.status == DriverSettlementStatus.voided) {
        return false;
      }
      if (driverIdFilter != null && settlement.driverId != driverIdFilter) {
        return false;
      }
      if (statusFilter != null && settlement.status != statusFilter) {
        return false;
      }
      if (normalizedSearch.isEmpty) return true;

      final calculation = settlement.calculation;
      final searchTerms = <Object?>[
        driverLabel(settlement.driverId),
        settlement.period.start.toIso8601String(),
        settlement.period.end.toIso8601String(),
        settlement.status.value,
        ...(statusSearchTerms[settlement.status] ?? const <String>[]),
        settlement.notes,
        calculation.netSalaryPayable,
        calculation.closingDriverBalance,
        calculation.grossSalary,
      ];
      return searchTerms.any((term) {
        if (term == null) return false;
        return normalizeSearchText(term.toString()).contains(normalizedSearch);
      });
    }).toList(growable: false);
  }

  bool isPending(String settlementId) {
    return pendingActionSettlementId == settlementId;
  }

  DriverSettlementsLoaded copyWith({
    List<DriverSettlement>? allSettlements,
    List<DriverSettlementDriverOption>? driverOptions,
    bool? canManageDriverSettlements,
    String? searchQuery,
    Object? driverIdFilter = _notSet,
    Object? statusFilter = _notSet,
    bool? includeVoided,
    Object? pendingActionSettlementId = _notSet,
    bool? isPreviewLoading,
    Object? preview = _notSet,
    Object? previewFailure = _notSet,
    bool? isCreatingDraft,
    Object? selectedSettlement = _notSet,
    bool? isDetailsLoading,
    Object? detailsFailure = _notSet,
    List<AuditLog>? selectedSettlementActivity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
    Object? mutationFailure = _notSet,
    Object? feedback = _notSet,
  }) {
    return DriverSettlementsLoaded(
      currentCompanyContext: currentCompanyContext,
      allSettlements: allSettlements ?? this.allSettlements,
      driverOptions: driverOptions ?? this.driverOptions,
      canManageDriverSettlements:
          canManageDriverSettlements ?? this.canManageDriverSettlements,
      searchQuery: searchQuery ?? this.searchQuery,
      driverIdFilter: driverIdFilter == _notSet
          ? this.driverIdFilter
          : driverIdFilter as String?,
      statusFilter: statusFilter == _notSet
          ? this.statusFilter
          : statusFilter as DriverSettlementStatus?,
      includeVoided: includeVoided ?? this.includeVoided,
      pendingActionSettlementId: pendingActionSettlementId == _notSet
          ? this.pendingActionSettlementId
          : pendingActionSettlementId as String?,
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      preview: preview == _notSet
          ? this.preview
          : preview as DriverSettlementPreview?,
      previewFailure: previewFailure == _notSet
          ? this.previewFailure
          : previewFailure as Failure?,
      isCreatingDraft: isCreatingDraft ?? this.isCreatingDraft,
      selectedSettlement: selectedSettlement == _notSet
          ? this.selectedSettlement
          : selectedSettlement as DriverSettlement?,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      detailsFailure: detailsFailure == _notSet
          ? this.detailsFailure
          : detailsFailure as Failure?,
      selectedSettlementActivity:
          selectedSettlementActivity ?? this.selectedSettlementActivity,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
      mutationFailure: mutationFailure == _notSet
          ? this.mutationFailure
          : mutationFailure as Failure?,
      feedback: feedback == _notSet
          ? this.feedback
          : feedback as DriverSettlementFeedback?,
    );
  }
}

class DriverSettlementsFailure extends DriverSettlementsState {
  final Failure failure;

  const DriverSettlementsFailure(this.failure);
}
