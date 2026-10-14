part of 'fleet_cubit.dart';

/// Fleet write orchestration stays in Presentation and invokes Domain use cases.
/// Tenant/session guards prevent late results from replacing another company.
mixin FleetMutationActions on Cubit<FleetState> {
  Future<void> saveTractorHead({
    TractorHead? tractorHead,
    required String plateNumber,
    required VehicleStatus status,
    BusinessDate? licenseExpiryDate,
    double? expectedFuelConsumption,
    String? notes,
  }) async {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    if (context == null || !owner._isCurrentFleetContext(context)) return;
    if (tractorHead != null && tractorHead.companyId != context.companyId) {
      emit(
        const FleetFailure(
          PermissionFailure(code: FailureCodes.permissionFleetManagement),
        ),
      );
      return;
    }

    final businessDateResult = await owner.getCurrentBusinessDate();
    if (!owner._isCurrentFleetContext(context)) return;
    final businessDateFailure = businessDateResult.failureOrNull;
    if (businessDateFailure != null) {
      emit(FleetFailure(businessDateFailure));
      return;
    }
    final currentBusinessDate = businessDateResult.dataOrNull;
    if (currentBusinessDate == null) {
      emit(const FleetFailure(UnexpectedFailure()));
      return;
    }

    final result = await owner.saveTractorHeadUseCase(
      SaveTractorHeadParams(
        currentCompanyContext: context,
        id: tractorHead?.id,
        plateNumber: plateNumber,
        status: status,
        licenseExpiryDate: licenseExpiryDate,
        currentBusinessDate: currentBusinessDate,
        expectedFuelConsumption: expectedFuelConsumption,
        notes: notes,
      ),
    );
    if (!owner._isCurrentFleetContext(context)) return;
    result.when(
      success: _upsertTractorHead,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  Future<void> saveTrailer({
    TrailerEntity? trailer,
    required String plateNumber,
    required VehicleStatus status,
    BusinessDate? licenseExpiryDate,
    String? technicalNotes,
  }) async {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    if (context == null || !owner._isCurrentFleetContext(context)) return;
    if (trailer != null && trailer.companyId != context.companyId) {
      emit(
        const FleetFailure(
          PermissionFailure(code: FailureCodes.permissionFleetManagement),
        ),
      );
      return;
    }

    final businessDateResult = await owner.getCurrentBusinessDate();
    if (!owner._isCurrentFleetContext(context)) return;
    final businessDateFailure = businessDateResult.failureOrNull;
    if (businessDateFailure != null) {
      emit(FleetFailure(businessDateFailure));
      return;
    }
    final currentBusinessDate = businessDateResult.dataOrNull;
    if (currentBusinessDate == null) {
      emit(const FleetFailure(UnexpectedFailure()));
      return;
    }

    final result = await owner.saveTrailerUseCase(
      SaveTrailerParams(
        currentCompanyContext: context,
        id: trailer?.id,
        plateNumber: plateNumber,
        status: status,
        licenseExpiryDate: licenseExpiryDate,
        currentBusinessDate: currentBusinessDate,
        technicalNotes: technicalNotes,
      ),
    );
    if (!owner._isCurrentFleetContext(context)) return;
    result.when(
      success: _upsertTrailer,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  Future<void> deactivateTractorHead(TractorHead item) {
    final owner = this as FleetCubit;
    return _changeTractorHeadActiveState(
      item,
      owner.deactivateTractorHeadUseCase.call,
    );
  }

  Future<void> reactivateTractorHead(TractorHead item) {
    final owner = this as FleetCubit;
    return _changeTractorHeadActiveState(
      item,
      owner.reactivateTractorHeadUseCase.call,
    );
  }

  Future<void> deactivateTrailer(TrailerEntity item) {
    final owner = this as FleetCubit;
    return _changeTrailerActiveState(item, owner.deactivateTrailerUseCase.call);
  }

  Future<void> reactivateTrailer(TrailerEntity item) {
    final owner = this as FleetCubit;
    return _changeTrailerActiveState(item, owner.reactivateTrailerUseCase.call);
  }

  Future<void> _changeTractorHeadActiveState(
    TractorHead item,
    Future<Result<TractorHead>> Function(FleetAssetStatusParams params) useCase,
  ) async {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    if (context == null ||
        !owner._isCurrentFleetContext(context) ||
        item.companyId != context.companyId ||
        _isAssetActionRunning(item.id)) {
      return;
    }
    final id = item.id;
    _setAssetActionRunning(id, true);
    final result = await useCase(
      FleetAssetStatusParams(currentCompanyContext: context, id: id),
    );
    if (!owner._isCurrentFleetContext(context)) return;
    _setAssetActionRunning(id, false);
    result.when(
      success: _upsertTractorHead,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  Future<void> _changeTrailerActiveState(
    TrailerEntity item,
    Future<Result<TrailerEntity>> Function(FleetAssetStatusParams params)
    useCase,
  ) async {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    if (context == null ||
        !owner._isCurrentFleetContext(context) ||
        item.companyId != context.companyId ||
        _isAssetActionRunning(item.id)) {
      return;
    }
    final id = item.id;
    _setAssetActionRunning(id, true);
    final result = await useCase(
      FleetAssetStatusParams(currentCompanyContext: context, id: id),
    );
    if (!owner._isCurrentFleetContext(context)) return;
    _setAssetActionRunning(id, false);
    result.when(
      success: _upsertTrailer,
      failure: (failure) => emit(FleetFailure(failure)),
    );
  }

  void _upsertTractorHead(TractorHead item) {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    if (context == null ||
        !owner._isCurrentFleetContext(context) ||
        item.companyId != context.companyId) {
      return;
    }
    owner._didApplyLocalAssetMutation();
    if (state is! FleetLoaded) {
      unawaited(owner.loadFleet(context));
      return;
    }
    owner._mapLoaded(
      (loaded) => loaded.copyWith(
        allTractorHeads: _upsertById(
          loaded.allTractorHeads,
          item,
          (current) => current.id,
        ),
      ),
    );
  }

  void _upsertTrailer(TrailerEntity item) {
    final owner = this as FleetCubit;
    final context = owner._currentCompanyContext;
    if (context == null ||
        !owner._isCurrentFleetContext(context) ||
        item.companyId != context.companyId) {
      return;
    }
    owner._didApplyLocalAssetMutation();
    if (state is! FleetLoaded) {
      unawaited(owner.loadFleet(context));
      return;
    }
    owner._mapLoaded(
      (loaded) => loaded.copyWith(
        allTrailers: _upsertById(
          loaded.allTrailers,
          item,
          (current) => current.id,
        ),
      ),
    );
  }

  bool _isAssetActionRunning(String id) =>
      state is FleetLoaded && (state as FleetLoaded).isActiveStateChanging(id);

  void _setAssetActionRunning(String id, bool isRunning) {
    final owner = this as FleetCubit;
    owner._mapLoaded((s) {
      final ids = {...s.activeStateChangingAssetIds};
      isRunning ? ids.add(id) : ids.remove(id);
      return s.copyWith(activeStateChangingAssetIds: ids);
    });
  }

}
