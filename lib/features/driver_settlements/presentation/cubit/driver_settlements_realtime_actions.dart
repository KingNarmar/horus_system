part of 'driver_settlements_cubit.dart';

/// Reconciles mounted settlement views without resetting form/selection state.
mixin DriverSettlementsRealtimeActions on Cubit<DriverSettlementsState> {
  Future<void> reconcileSettlementsAfterReconnect(
    CurrentCompanyContext context,
  ) async {
    final owner = this as DriverSettlementsCubit;
    final current = state;
    if (current is DriverSettlementsInitial ||
        current is DriverSettlementsFailure) {
      await owner.loadDriverSettlements(context);
      return;
    }
    if (current is DriverSettlementsLoading) {
      owner._realtimeRefreshPending = true;
      return;
    }
    if (current is! DriverSettlementsLoaded ||
        current.currentCompanyContext.companyId != context.companyId ||
        current.currentCompanyContext.role != context.role) {
      return;
    }
    await refreshDriverSettlementsFromRealtime();
    await refreshSettlementDriverOptionsFromRealtime();
  }

  Future<void> refreshDriverSettlementsFromRealtime() async {
    final owner = this as DriverSettlementsCubit;
    if (owner.isClosed) return;
    final current = state;
    if (current is DriverSettlementsLoading) {
      owner._realtimeRefreshPending = true;
      return;
    }
    if (current is! DriverSettlementsLoaded) return;
    if (current.isCreatingDraft ||
        current.pendingActionSettlementId != null ||
        owner._realtimeRefreshInProgress) {
      owner._realtimeRefreshPending = true;
      return;
    }
    owner._realtimeRefreshInProgress = true;
    try {
      do {
        owner._realtimeRefreshPending = false;
        await _refreshOnce();
      } while (owner._realtimeRefreshPending &&
          !owner.isClosed &&
          state is DriverSettlementsLoaded &&
          !(state as DriverSettlementsLoaded).isCreatingDraft &&
          (state as DriverSettlementsLoaded).pendingActionSettlementId == null);
    } finally {
      owner._realtimeRefreshInProgress = false;
    }
  }

  Future<void> _refreshOnce() async {
    final owner = this as DriverSettlementsCubit;
    final before = state;
    if (before is! DriverSettlementsLoaded) return;
    final context = before.currentCompanyContext;
    final generation = owner._loadRequestGeneration;
    final mutationRevision = owner._settlementMutationRevision;
    final includeVoided = before.includeVoided;
    final selectedId = before.selectedSettlement?.id;

    bool stillCurrent() {
      final active = state;
      return !owner.isClosed &&
          owner._loadRequestGeneration == generation &&
          owner._settlementMutationRevision == mutationRevision &&
          owner._currentCompanyContext?.companyId == context.companyId &&
          active is DriverSettlementsLoaded &&
          active.currentCompanyContext.companyId == context.companyId &&
          active.currentCompanyContext.role == context.role &&
          active.includeVoided == includeVoided &&
          active.selectedSettlement?.id == selectedId &&
          !active.isCreatingDraft &&
          active.pendingActionSettlementId == null;
    }

    final list = await owner.getDriverSettlementsUseCase(
      GetDriverSettlementsParams(
        currentCompanyContext: context,
        includeVoided: includeVoided,
      ),
    );
    if (!stillCurrent()) {
      if (owner._loadRequestGeneration == generation) {
        owner._realtimeRefreshPending = true;
      }
      return;
    }
    if (_realtimeFailure(list.failureOrNull)) return;

    DriverSettlement? selected;
    if (selectedId != null) {
      final details = await owner.getDriverSettlementDetailsUseCase(
        GetDriverSettlementDetailsParams(
          currentCompanyContext: context,
          settlementId: selectedId,
        ),
      );
      if (!stillCurrent()) {
        if (owner._loadRequestGeneration == generation) {
          owner._realtimeRefreshPending = true;
        }
        return;
      }
      if (_realtimeFailure(details.failureOrNull)) return;
      selected = details.dataOrNull;
    }

    final active = state as DriverSettlementsLoaded;
    final changed = selected != null &&
        (selected.status != active.selectedSettlement?.status ||
            selected.updatedAt != active.selectedSettlement?.updatedAt);
    emit(active.copyWith(
      allSettlements: List.unmodifiable(list.dataOrNull ?? const []),
      selectedSettlement: selected ?? active.selectedSettlement,
      realtimeRefreshFailure: null,
    ));
    if (changed && selected != null) {
      final times = await owner._projectSettlementTimestamps(context, selected);
      if (!stillCurrent()) return;
      if (_realtimeFailure(times.failureOrNull)) return;
      emit(owner._applySettlementTimestamps(
        state as DriverSettlementsLoaded,
        times.dataOrNull ?? const <String, BusinessLocalDateTime>{},
      ));
      await owner._loadSettlementActivity(selected);
    }
  }

  Future<void> refreshSettlementDriverOptionsFromRealtime() async {
    final owner = this as DriverSettlementsCubit;
    final before = state;
    if (owner.isClosed || before is! DriverSettlementsLoaded) return;
    final context = before.currentCompanyContext;
    final generation = owner._loadRequestGeneration;
    final options = await owner.getDriverOptionsUseCase(
      GetDriverSettlementDriverOptionsParams(
        currentCompanyContext: context,
      ),
    );
    final active = state;
    if (owner.isClosed ||
        generation != owner._loadRequestGeneration ||
        active is! DriverSettlementsLoaded ||
        active.currentCompanyContext.companyId != context.companyId) {
      return;
    }
    if (_realtimeFailure(options.failureOrNull)) return;
    emit(active.copyWith(
      driverOptions: List.unmodifiable(options.dataOrNull ?? const []),
      realtimeRefreshFailure: null,
    ));
  }

  bool _realtimeFailure(Failure? failure) {
    if (failure == null) return false;
    final current = state;
    if (failure is AuthFailure || failure is PermissionFailure) {
      emit(DriverSettlementsFailure(failure));
    } else if (current is DriverSettlementsLoaded) {
      emit(current.copyWith(realtimeRefreshFailure: failure));
    }
    return true;
  }
}
