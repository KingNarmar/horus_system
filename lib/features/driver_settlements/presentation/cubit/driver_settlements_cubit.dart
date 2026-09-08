import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver_settlement.dart';
import '../../domain/entities/driver_settlement_driver_option.dart';
import '../../domain/entities/driver_settlement_status.dart';
import '../../domain/policies/driver_settlements_permission_policy.dart';
import '../../domain/usecases/driver_settlement_usecases.dart';
import 'driver_settlement_form_input.dart';
import 'driver_settlements_state.dart';

part 'driver_settlements_filter_actions.dart';

const _settlementCreatedAtKey = 'settlement_created_at';
const _settlementFinalizedAtKey = 'settlement_finalized_at';
const _settlementVoidedAtKey = 'settlement_voided_at';

class DriverSettlementsCubit extends Cubit<DriverSettlementsState>
    with DriverSettlementsFilterActions {
  final GetDriverSettlementsUseCase getDriverSettlementsUseCase;
  final GetDriverSettlementDriverOptionsUseCase getDriverOptionsUseCase;
  final GetDriverSettlementBusinessDateUseCase getBusinessDateUseCase;
  final GetDriverSettlementDetailsUseCase getDriverSettlementDetailsUseCase;
  final CalculateDriverSettlementPreviewUseCase calculatePreviewUseCase;
  final CreateDriverSettlementDraftUseCase createDraftUseCase;
  final FinalizeDriverSettlementUseCase finalizeSettlementUseCase;
  final VoidDriverSettlementUseCase voidSettlementUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;
  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _previewGeneration = 0;

  @override
  CurrentCompanyContext? get filterCompanyContext => _currentCompanyContext;

  DriverSettlementsCubit({
    required this.getDriverSettlementsUseCase,
    required this.getDriverOptionsUseCase,
    required this.getBusinessDateUseCase,
    required this.getDriverSettlementDetailsUseCase,
    required this.calculatePreviewUseCase,
    required this.createDraftUseCase,
    required this.finalizeSettlementUseCase,
    required this.voidSettlementUseCase,
    required this.getEntityAuditLogsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
  }) : super(const DriverSettlementsInitial());

  Future<void> loadDriverSettlements(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    _currentCompanyContext = currentCompanyContext;
    final previousState = state;
    final previousSearch = previousState is DriverSettlementsLoaded
        ? previousState.searchQuery
        : '';
    final previousDriverFilter = previousState is DriverSettlementsLoaded
        ? previousState.driverIdFilter
        : null;
    final previousStatusFilter = previousState is DriverSettlementsLoaded
        ? previousState.statusFilter
        : null;
    final previousIncludeVoided = previousState is DriverSettlementsLoaded
        ? previousState.includeVoided
        : false;

    emit(const DriverSettlementsLoading());

    final businessDateResult = await getBusinessDateUseCase(
      GetDriverSettlementBusinessDateParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (businessDateResult is FailureResult<BusinessDate>) {
      emit(DriverSettlementsFailure(businessDateResult.failure));
      return;
    }

    final optionsResult = await getDriverOptionsUseCase(
      GetDriverSettlementDriverOptionsParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (optionsResult is FailureResult<List<DriverSettlementDriverOption>>) {
      emit(DriverSettlementsFailure(optionsResult.failure));
      return;
    }

    final settlementsResult = await getDriverSettlementsUseCase(
      GetDriverSettlementsParams(
        currentCompanyContext: currentCompanyContext,
        includeVoided: previousIncludeVoided,
      ),
    );
    if (settlementsResult is FailureResult<List<DriverSettlement>>) {
      emit(DriverSettlementsFailure(settlementsResult.failure));
      return;
    }

    emit(
      DriverSettlementsLoaded(
        currentCompanyContext: currentCompanyContext,
        businessDate: (businessDateResult as Success<BusinessDate>).data,
        allSettlements: settlementsResult.dataOrNull ?? const [],
        driverOptions: optionsResult.dataOrNull ?? const [],
        canManageDriverSettlements:
            DriverSettlementsPermissionPolicy.canManageDriverSettlements(
              currentCompanyContext.role,
            ),
        searchQuery: previousSearch,
        driverIdFilter: previousDriverFilter,
        statusFilter: previousStatusFilter,
        includeVoided: previousIncludeVoided,
      ),
    );
  }

  void invalidatePreview() {
    _previewGeneration++;
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(
        currentState.copyWith(
          isPreviewLoading: false,
          preview: null,
          previewFailure: null,
        ),
      );
    }
  }

  Future<void> calculatePreview(DriverSettlementFormInput input) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded || context == null) return;

    final generation = ++_previewGeneration;
    emit(
      currentState.copyWith(
        isPreviewLoading: true,
        preview: null,
        previewFailure: null,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await calculatePreviewUseCase(
      input.toCalculationParams(context),
    );
    if (generation != _previewGeneration) return;

    final latestState = state;
    if (latestState is! DriverSettlementsLoaded) return;
    result.when(
      success: (preview) => emit(
        latestState.copyWith(
          isPreviewLoading: false,
          preview: preview,
          previewFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(
          isPreviewLoading: false,
          preview: null,
          previewFailure: failure,
        ),
      ),
    );
  }

  Future<bool> createDraft(DriverSettlementFormInput input) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded ||
        context == null ||
        currentState.isCreatingDraft) {
      return false;
    }

    emit(
      currentState.copyWith(
        isCreatingDraft: true,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await createDraftUseCase(input.toCreateDraftParams(context));

    final latestState = state;
    if (latestState is! DriverSettlementsLoaded) return false;

    if (result is FailureResult<DriverSettlement>) {
      emit(
        latestState.copyWith(
          isCreatingDraft: false,
          mutationFailure: result.failure,
        ),
      );
      return false;
    }

    final settlement = result.dataOrNull;
    if (settlement == null) return false;
    _previewGeneration++;
    emit(
      _upsertSettlement(latestState, settlement).copyWith(
        isCreatingDraft: false,
        preview: null,
        previewFailure: null,
        feedback: DriverSettlementFeedback.draftCreated,
      ),
    );
    return true;
  }

  Future<void> loadSettlementDetails(DriverSettlement settlement) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded || context == null) return;

    emit(
      currentState.copyWith(
        selectedSettlement: settlement,
        selectedSettlementCreatedAt: null,
        selectedSettlementFinalizedAt: null,
        selectedSettlementVoidedAt: null,
        isDetailsLoading: true,
        detailsFailure: null,
        selectedSettlementActivity: const [],
        selectedSettlementActivityTimestampsByLogId:
            const <String, BusinessLocalDateTime>{},
        isActivityLoading: true,
        activityFailure: null,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final detailsResult = await getDriverSettlementDetailsUseCase(
      GetDriverSettlementDetailsParams(
        currentCompanyContext: context,
        settlementId: settlement.id,
      ),
    );

    final detailsState = state;
    if (detailsState is! DriverSettlementsLoaded ||
        detailsState.selectedSettlement?.id != settlement.id) {
      return;
    }

    if (detailsResult is FailureResult<DriverSettlement>) {
      emit(
        detailsState.copyWith(
          isDetailsLoading: false,
          detailsFailure: detailsResult.failure,
          isActivityLoading: false,
        ),
      );
      return;
    }

    final details = detailsResult.dataOrNull ?? settlement;
    final timestampsResult = await _projectSettlementTimestamps(
      context,
      details,
    );
    final projectedState = state;
    if (projectedState is! DriverSettlementsLoaded ||
        projectedState.selectedSettlement?.id != settlement.id) {
      return;
    }
    if (timestampsResult is FailureResult<Map<String, BusinessLocalDateTime>>) {
      emit(
        _upsertSettlement(projectedState, details).copyWith(
          selectedSettlement: details,
          isDetailsLoading: false,
          detailsFailure: timestampsResult.failure,
          isActivityLoading: false,
        ),
      );
      return;
    }

    emit(
      _applySettlementTimestamps(
        _upsertSettlement(projectedState, details).copyWith(
          selectedSettlement: details,
          isDetailsLoading: false,
          detailsFailure: null,
        ),
        timestampsResult.dataOrNull ?? const <String, BusinessLocalDateTime>{},
      ),
    );

    await _loadSettlementActivity(details);
  }

  Future<bool> finalizeSettlement(DriverSettlement settlement) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded ||
        context == null ||
        currentState.pendingActionSettlementId != null) {
      return false;
    }

    emit(
      currentState.copyWith(
        pendingActionSettlementId: settlement.id,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await finalizeSettlementUseCase(
      FinalizeDriverSettlementParams(
        currentCompanyContext: context,
        settlementId: settlement.id,
      ),
    );
    return _finishStatusMutation(
      settlementId: settlement.id,
      result: result,
      feedback: DriverSettlementFeedback.finalized,
    );
  }

  Future<bool> voidSettlement(
    DriverSettlement settlement, {
    required String reason,
  }) async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded ||
        context == null ||
        currentState.pendingActionSettlementId != null) {
      return false;
    }

    emit(
      currentState.copyWith(
        pendingActionSettlementId: settlement.id,
        mutationFailure: null,
        feedback: null,
      ),
    );

    final result = await voidSettlementUseCase(
      VoidDriverSettlementParams(
        currentCompanyContext: context,
        settlementId: settlement.id,
        reason: reason,
      ),
    );
    return _finishStatusMutation(
      settlementId: settlement.id,
      result: result,
      feedback: DriverSettlementFeedback.voided,
    );
  }

  void clearSettlementDetails() {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(
        currentState.copyWith(
          selectedSettlement: null,
          selectedSettlementCreatedAt: null,
          selectedSettlementFinalizedAt: null,
          selectedSettlementVoidedAt: null,
          isDetailsLoading: false,
          detailsFailure: null,
          selectedSettlementActivity: const [],
          selectedSettlementActivityTimestampsByLogId:
              const <String, BusinessLocalDateTime>{},
          isActivityLoading: false,
          activityFailure: null,
          mutationFailure: null,
          feedback: null,
        ),
      );
    }
  }

  void clearFeedback() {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(mutationFailure: null, feedback: null));
    }
  }

  Future<void> _loadSettlementActivity(DriverSettlement settlement) async {
    final context = _currentCompanyContext;
    if (context == null) return;

    final result = await getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context.companyId,
        module: AuditModule.drivers,
        entityType: AuditEntityType.driver,
        entityId: settlement.driverId,
      ),
    );

    final latestState = state;
    if (latestState is! DriverSettlementsLoaded ||
        latestState.selectedSettlement?.id != settlement.id) {
      return;
    }

    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      );
      return;
    }

    final settlementLogs = (result.dataOrNull ?? const [])
        .where((log) {
          return log.metadata?['settlement_id']?.toString() == settlement.id;
        })
        .toList(growable: false);
    final timestampsResult = await _convertCompanyInstants(context, {
      for (final log in settlementLogs) log.id: log.createdAt,
    });

    final projectedState = state;
    if (projectedState is! DriverSettlementsLoaded ||
        projectedState.selectedSettlement?.id != settlement.id) {
      return;
    }
    final timestampFailure = timestampsResult.failureOrNull;
    if (timestampFailure != null) {
      emit(
        projectedState.copyWith(
          selectedSettlementActivity: const [],
          selectedSettlementActivityTimestampsByLogId:
              const <String, BusinessLocalDateTime>{},
          isActivityLoading: false,
          activityFailure: timestampFailure,
        ),
      );
      return;
    }

    emit(
      projectedState.copyWith(
        selectedSettlementActivity: settlementLogs,
        selectedSettlementActivityTimestampsByLogId:
            timestampsResult.dataOrNull ??
            const <String, BusinessLocalDateTime>{},
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }

  Future<Result<Map<String, BusinessLocalDateTime>>>
  _projectSettlementTimestamps(
    CurrentCompanyContext currentCompanyContext,
    DriverSettlement settlement,
  ) {
    return _convertCompanyInstants(currentCompanyContext, <String, DateTime>{
      if (settlement.createdAt != null)
        _settlementCreatedAtKey: settlement.createdAt!,
      if (settlement.finalizedAt != null)
        _settlementFinalizedAtKey: settlement.finalizedAt!,
      if (settlement.voidedAt != null)
        _settlementVoidedAtKey: settlement.voidedAt!,
    });
  }

  Future<Result<Map<String, BusinessLocalDateTime>>> _convertCompanyInstants(
    CurrentCompanyContext currentCompanyContext,
    Map<String, DateTime> instantsByKey,
  ) {
    return convertInstantsToBusinessLocalDateTimesUseCase(
      ConvertInstantsToBusinessLocalDateTimesParams(
        timeZoneId: currentCompanyContext.company.businessTimezone ?? '',
        instantsByKey: instantsByKey,
      ),
    );
  }

  DriverSettlementsLoaded _applySettlementTimestamps(
    DriverSettlementsLoaded currentState,
    Map<String, BusinessLocalDateTime> timestamps,
  ) {
    return currentState.copyWith(
      selectedSettlementCreatedAt: timestamps[_settlementCreatedAtKey],
      selectedSettlementFinalizedAt: timestamps[_settlementFinalizedAtKey],
      selectedSettlementVoidedAt: timestamps[_settlementVoidedAtKey],
    );
  }

  Future<bool> _finishStatusMutation({
    required String settlementId,
    required Result<DriverSettlement> result,
    required DriverSettlementFeedback feedback,
  }) async {
    final latestState = state;
    if (latestState is! DriverSettlementsLoaded ||
        latestState.pendingActionSettlementId != settlementId) {
      return false;
    }

    if (result is FailureResult<DriverSettlement>) {
      emit(
        latestState.copyWith(
          pendingActionSettlementId: null,
          mutationFailure: result.failure,
        ),
      );
      return false;
    }

    final settlement = result.dataOrNull;
    if (settlement == null) return false;
    final context = _currentCompanyContext;
    if (context == null) return false;

    final timestampsResult = await _projectSettlementTimestamps(
      context,
      settlement,
    );
    final currentState = state;
    if (currentState is! DriverSettlementsLoaded ||
        currentState.pendingActionSettlementId != settlementId) {
      return false;
    }

    final baseState = _upsertSettlement(currentState, settlement).copyWith(
      selectedSettlement: settlement,
      pendingActionSettlementId: null,
      mutationFailure: null,
      feedback: feedback,
    );
    final timestampFailure = timestampsResult.failureOrNull;
    if (timestampFailure != null) {
      emit(
        baseState.copyWith(
          selectedSettlementCreatedAt: null,
          selectedSettlementFinalizedAt: null,
          selectedSettlementVoidedAt: null,
          detailsFailure: timestampFailure,
        ),
      );
      return true;
    }

    final updatedState = _applySettlementTimestamps(
      baseState.copyWith(detailsFailure: null),
      timestampsResult.dataOrNull ?? const <String, BusinessLocalDateTime>{},
    );
    emit(updatedState);
    await _loadSettlementActivity(settlement);
    return true;
  }

  DriverSettlementsLoaded _upsertSettlement(
    DriverSettlementsLoaded currentState,
    DriverSettlement settlement,
  ) {
    final exists = currentState.allSettlements.any(
      (item) => item.id == settlement.id,
    );
    final settlements = exists
        ? currentState.allSettlements
              .map((item) => item.id == settlement.id ? settlement : item)
              .toList(growable: false)
        : [settlement, ...currentState.allSettlements];
    return currentState.copyWith(allSettlements: settlements);
  }
}
