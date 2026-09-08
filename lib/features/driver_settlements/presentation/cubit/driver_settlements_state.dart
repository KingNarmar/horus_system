import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
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
  final BusinessDate businessDate;
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
  final BusinessLocalDateTime? selectedSettlementCreatedAt;
  final BusinessLocalDateTime? selectedSettlementFinalizedAt;
  final BusinessLocalDateTime? selectedSettlementVoidedAt;
  final bool isDetailsLoading;
  final Failure? detailsFailure;
  final List<AuditLog> selectedSettlementActivity;
  final Map<String, BusinessLocalDateTime>
  selectedSettlementActivityTimestampsByLogId;
  final bool isActivityLoading;
  final Failure? activityFailure;
  final Failure? mutationFailure;
  final DriverSettlementFeedback? feedback;

  const DriverSettlementsLoaded({
    required this.currentCompanyContext,
    required this.businessDate,
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
    this.selectedSettlementCreatedAt,
    this.selectedSettlementFinalizedAt,
    this.selectedSettlementVoidedAt,
    this.isDetailsLoading = false,
    this.detailsFailure,
    this.selectedSettlementActivity = const [],
    this.selectedSettlementActivityTimestampsByLogId =
        const <String, BusinessLocalDateTime>{},
    this.isActivityLoading = false,
    this.activityFailure,
    this.mutationFailure,
    this.feedback,
  });

  List<DriverSettlementDriverOption> get activeDriverOptions =>
      driverOptions.where((option) => option.isActive).toList(growable: false);

  String? driverLabel(String driverId) {
    for (final option in driverOptions) {
      if (option.id == driverId) return option.displayName;
    }
    return null;
  }

  BusinessLocalDateTime? activityTimestampFor(String logId) {
    return selectedSettlementActivityTimestampsByLogId[logId];
  }

  List<DriverSettlement> get settlements => filteredSettlements();

  List<DriverSettlement> filteredSettlements({
    Map<DriverSettlementStatus, Iterable<String>> statusSearchTerms = const {},
  }) {
    final normalizedSearch = normalizeSearchText(searchQuery);
    return allSettlements
        .where((settlement) {
          if (!includeVoided &&
              settlement.status == DriverSettlementStatus.voided) {
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
            _businessDateSearchValue(settlement.period.start),
            _businessDateSearchValue(settlement.period.end),
            settlement.status.value,
            ...(statusSearchTerms[settlement.status] ?? const <String>[]),
            settlement.notes,
            calculation.netSalaryPayable,
            calculation.closingDriverBalance,
            calculation.grossSalary,
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
    Object? selectedSettlementCreatedAt = _notSet,
    Object? selectedSettlementFinalizedAt = _notSet,
    Object? selectedSettlementVoidedAt = _notSet,
    bool? isDetailsLoading,
    Object? detailsFailure = _notSet,
    List<AuditLog>? selectedSettlementActivity,
    Map<String, BusinessLocalDateTime>?
    selectedSettlementActivityTimestampsByLogId,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
    Object? mutationFailure = _notSet,
    Object? feedback = _notSet,
  }) {
    return DriverSettlementsLoaded(
      currentCompanyContext: currentCompanyContext,
      businessDate: businessDate,
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
      selectedSettlementCreatedAt: selectedSettlementCreatedAt == _notSet
          ? this.selectedSettlementCreatedAt
          : selectedSettlementCreatedAt as BusinessLocalDateTime?,
      selectedSettlementFinalizedAt: selectedSettlementFinalizedAt == _notSet
          ? this.selectedSettlementFinalizedAt
          : selectedSettlementFinalizedAt as BusinessLocalDateTime?,
      selectedSettlementVoidedAt: selectedSettlementVoidedAt == _notSet
          ? this.selectedSettlementVoidedAt
          : selectedSettlementVoidedAt as BusinessLocalDateTime?,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      detailsFailure: detailsFailure == _notSet
          ? this.detailsFailure
          : detailsFailure as Failure?,
      selectedSettlementActivity:
          selectedSettlementActivity ?? this.selectedSettlementActivity,
      selectedSettlementActivityTimestampsByLogId:
          selectedSettlementActivityTimestampsByLogId ??
          this.selectedSettlementActivityTimestampsByLogId,
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

String _businessDateSearchValue(BusinessDate value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
