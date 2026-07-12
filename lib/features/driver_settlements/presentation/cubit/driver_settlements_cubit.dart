import 'package:flutter_bloc/flutter_bloc.dart';

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

class DriverSettlementsCubit extends Cubit<DriverSettlementsState> {
  final GetDriverSettlementsUseCase getDriverSettlementsUseCase;
  final GetDriverSettlementDriverOptionsUseCase getDriverOptionsUseCase;
  final GetDriverSettlementDetailsUseCase getDriverSettlementDetailsUseCase;
  final CalculateDriverSettlementPreviewUseCase calculatePreviewUseCase;
  final CreateDriverSettlementDraftUseCase createDraftUseCase;
  final FinalizeDriverSettlementUseCase finalizeSettlementUseCase;
  final VoidDriverSettlementUseCase voidSettlementUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _previewGeneration = 0;

  DriverSettlementsCubit({
    required this.getDriverSettlementsUseCase,
    required this.getDriverOptionsUseCase,
    required this.getDriverSettlementDetailsUseCase,
    required this.calculatePreviewUseCase,
    required this.createDraftUseCase,
    required this.finalizeSettlementUseCase,
    required this.voidSettlementUseCase,
    required this.getEntityAuditLogsUseCase,
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

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void setDriverFilter(String? driverId) {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(driverIdFilter: driverId));
    }
  }

  void setStatusFilter(DriverSettlementStatus? status) {
    final currentState = state;
    if (currentState is DriverSettlementsLoaded) {
      emit(currentState.copyWith(statusFilter: status));
    }
  }

  Future<void> setIncludeVoided(bool includeVoided) async {
    final currentState = state;
    if (currentState is! DriverSettlementsLoaded) return;
    emit(
      currentState.copyWith(
        includeVoided: includeVoided,
        mutationFailure: null,
        feedback: null,
      ),
    );
    await _reloadSettlements();
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

    final result = await createDraftUseCase(
      input.toCreateDraftParams(context),
    );

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
      _upsertSettlement(
        latestState,
        settlement,
      ).copyWith(
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
        isDetailsLoading: true,
        detailsFailure: null,
        selectedSettlementActivity: const [],
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
    emit(
      _upsertSettlement(detailsState, details).copyWith(
        selectedSettlement: details,
        isDetailsLoading: false,
        detailsFailure: null,
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
          isDetailsLoading: false,
          detailsFailure: null,
          selectedSettlementActivity: const [],
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
      emit(
        currentState.copyWith(
          mutationFailure: null,
          feedback: null,
        ),
      );
    }
  }

  Future<void> _reloadSettlements() async {
    final currentState = state;
    final context = _currentCompanyContext;
    if (currentState is! DriverSettlementsLoaded || context == null) return;

    final result = await getDriverSettlementsUseCase(
      GetDriverSettlementsParams(
        currentCompanyContext: context,
        includeVoided: currentState.includeVoided,
      ),
    );
    final latestState = state;
    if (latestState is! DriverSettlementsLoaded) return;

    result.when(
      success: (settlements) => emit(
        latestState.copyWith(
          allSettlements: settlements,
          mutationFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latestState.copyWith(mutationFailure: failure),
      ),
    );
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

    result.when(
      success: (logs) {
        final settlementLogs = logs.where((log) {
          return log.metadata?['settlement_id']?.toString() == settlement.id;
        }).toList(growable: false);
        emit(
          latestState.copyWith(
            selectedSettlementActivity: settlementLogs,
            isActivityLoading: false,
            activityFailure: null,
          ),
        );
      },
      failure: (failure) => emit(
        latestState.copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      ),
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
    final updatedState = _upsertSettlement(latestState, settlement).copyWith(
      selectedSettlement: settlement,
      pendingActionSettlementId: null,
      mutationFailure: null,
      feedback: feedback,
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
