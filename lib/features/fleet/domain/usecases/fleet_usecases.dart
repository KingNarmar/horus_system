import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/tractor_head.dart';
import '../entities/tractor_head_write_data.dart';
import '../entities/trailer_entity.dart';
import '../entities/trailer_write_data.dart';
import '../entities/vehicle_status.dart';
import '../policies/fleet_permission_policy.dart';
import '../repositories/fleet_repository.dart';

class GetFleetParams {
  final CurrentCompanyContext currentCompanyContext;
  const GetFleetParams({required this.currentCompanyContext});
}

class CanManageFleetParams {
  final CurrentCompanyContext currentCompanyContext;
  const CanManageFleetParams({required this.currentCompanyContext});
}

class SaveTractorHeadParams {
  final CurrentCompanyContext currentCompanyContext;
  final String? id;
  final String plateNumber;
  final VehicleStatus status;
  final DateTime? licenseExpiryDate;
  final double? expectedFuelConsumption;
  final String? notes;
  const SaveTractorHeadParams({
    required this.currentCompanyContext,
    this.id,
    required this.plateNumber,
    required this.status,
    this.licenseExpiryDate,
    this.expectedFuelConsumption,
    this.notes,
  });
}

class SaveTrailerParams {
  final CurrentCompanyContext currentCompanyContext;
  final String? id;
  final String plateNumber;
  final VehicleStatus status;
  final DateTime? licenseExpiryDate;
  final String? technicalNotes;
  const SaveTrailerParams({
    required this.currentCompanyContext,
    this.id,
    required this.plateNumber,
    required this.status,
    this.licenseExpiryDate,
    this.technicalNotes,
  });
}

class FleetAssetStatusParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;
  const FleetAssetStatusParams({
    required this.currentCompanyContext,
    required this.id,
  });
}

class GetTractorHeadsUseCase
    implements UseCase<List<TractorHead>, GetFleetParams> {
  final FleetRepository _repository;
  const GetTractorHeadsUseCase(this._repository);
  @override
  Future<Result<List<TractorHead>>> call(GetFleetParams params) {
    final context = params.currentCompanyContext;
    if (!FleetPermissionPolicy.canViewFleet(context.role)) {
      return Future.value(
        const FailureResult<List<TractorHead>>(
          PermissionFailure(
            code: FailureCodes.permissionFleetView,
            message: 'Fleet access is not allowed.',
          ),
        ),
      );
    }
    return _repository.getTractorHeads(companyId: context.companyId);
  }
}

class GetTrailersUseCase
    implements UseCase<List<TrailerEntity>, GetFleetParams> {
  final FleetRepository _repository;
  const GetTrailersUseCase(this._repository);
  @override
  Future<Result<List<TrailerEntity>>> call(GetFleetParams params) {
    final context = params.currentCompanyContext;
    if (!FleetPermissionPolicy.canViewFleet(context.role)) {
      return Future.value(
        const FailureResult<List<TrailerEntity>>(
          PermissionFailure(
            code: FailureCodes.permissionFleetView,
            message: 'Fleet access is not allowed.',
          ),
        ),
      );
    }
    return _repository.getTrailers(companyId: context.companyId);
  }
}

class CanManageFleetUseCase implements UseCase<bool, CanManageFleetParams> {
  const CanManageFleetUseCase();

  @override
  Future<Result<bool>> call(CanManageFleetParams params) {
    return Future.value(
      Success<bool>(
        FleetPermissionPolicy.canManageFleet(
          params.currentCompanyContext.role,
        ),
      ),
    );
  }
}

class SaveTractorHeadUseCase
    implements UseCase<TractorHead, SaveTractorHeadParams> {
  final FleetRepository _repository;
  const SaveTractorHeadUseCase(this._repository);
  @override
  Future<Result<TractorHead>> call(SaveTractorHeadParams params) {
    final context = params.currentCompanyContext;
    if (!FleetPermissionPolicy.canManageFleet(context.role)) {
      return Future.value(
        const FailureResult<TractorHead>(
          PermissionFailure(
            code: FailureCodes.permissionFleetManagement,
            message: 'Fleet management is not allowed.',
          ),
        ),
      );
    }
    final plateNumber = params.plateNumber.trim();
    if (plateNumber.isEmpty) {
      return Future.value(
        const FailureResult<TractorHead>(
          ValidationFailure(
            code: FailureCodes.validationFleetPlateRequired,
            message: 'Plate number is required.',
          ),
        ),
      );
    }
    final fuel = params.expectedFuelConsumption;
    if (fuel != null && fuel < 0) {
      return Future.value(
        const FailureResult<TractorHead>(
          ValidationFailure(
            code: FailureCodes.validationFleetFuelConsumptionNegative,
            message: 'Expected fuel consumption is invalid.',
          ),
        ),
      );
    }
    final data = TractorHeadWriteData(
      companyId: context.companyId,
      plateNumber: plateNumber,
      status: params.status,
      licenseExpiryDate: params.licenseExpiryDate,
      expectedFuelConsumption: fuel,
      notes: _normalizeOptional(params.notes),
    );
    final id = _normalizeOptional(params.id);
    if (id == null) {
      return _repository.addTractorHead(
        data: data,
        actorRole: context.role.value,
      );
    }
    return _repository.saveTractorHead(
      id: id,
      data: data,
      actorRole: context.role.value,
    );
  }
}

class SaveTrailerUseCase implements UseCase<TrailerEntity, SaveTrailerParams> {
  final FleetRepository _repository;
  const SaveTrailerUseCase(this._repository);
  @override
  Future<Result<TrailerEntity>> call(SaveTrailerParams params) {
    final context = params.currentCompanyContext;
    if (!FleetPermissionPolicy.canManageFleet(context.role)) {
      return Future.value(
        const FailureResult<TrailerEntity>(
          PermissionFailure(
            code: FailureCodes.permissionFleetManagement,
            message: 'Fleet management is not allowed.',
          ),
        ),
      );
    }
    final plateNumber = params.plateNumber.trim();
    if (plateNumber.isEmpty) {
      return Future.value(
        const FailureResult<TrailerEntity>(
          ValidationFailure(
            code: FailureCodes.validationFleetPlateRequired,
            message: 'Plate number is required.',
          ),
        ),
      );
    }
    final data = TrailerWriteData(
      companyId: context.companyId,
      plateNumber: plateNumber,
      status: params.status,
      licenseExpiryDate: params.licenseExpiryDate,
      technicalNotes: _normalizeOptional(params.technicalNotes),
    );
    final id = _normalizeOptional(params.id);
    if (id == null) {
      return _repository.addTrailer(data: data, actorRole: context.role.value);
    }
    return _repository.editTrailer(
      id: id,
      data: data,
      actorRole: context.role.value,
    );
  }
}

class DeactivateTractorHeadUseCase
    implements UseCase<TractorHead, FleetAssetStatusParams> {
  final FleetRepository _repository;
  const DeactivateTractorHeadUseCase(this._repository);
  @override
  Future<Result<TractorHead>> call(FleetAssetStatusParams params) =>
      _changeTractorHeadStatus(params, _repository.deactivateTractorHead);
}

class ReactivateTractorHeadUseCase
    implements UseCase<TractorHead, FleetAssetStatusParams> {
  final FleetRepository _repository;
  const ReactivateTractorHeadUseCase(this._repository);
  @override
  Future<Result<TractorHead>> call(FleetAssetStatusParams params) =>
      _changeTractorHeadStatus(params, _repository.reactivateTractorHead);
}

class DeactivateTrailerUseCase
    implements UseCase<TrailerEntity, FleetAssetStatusParams> {
  final FleetRepository _repository;
  const DeactivateTrailerUseCase(this._repository);
  @override
  Future<Result<TrailerEntity>> call(FleetAssetStatusParams params) =>
      _changeTrailerStatus(params, _repository.deactivateTrailer);
}

class ReactivateTrailerUseCase
    implements UseCase<TrailerEntity, FleetAssetStatusParams> {
  final FleetRepository _repository;
  const ReactivateTrailerUseCase(this._repository);
  @override
  Future<Result<TrailerEntity>> call(FleetAssetStatusParams params) =>
      _changeTrailerStatus(params, _repository.reactivateTrailer);
}

Future<Result<TractorHead>> _changeTractorHeadStatus(
  FleetAssetStatusParams params,
  Future<Result<TractorHead>> Function({
    required String companyId,
    required String id,
    required String actorRole,
  })
  action,
) {
  final context = params.currentCompanyContext;
  if (!FleetPermissionPolicy.canManageFleet(context.role)) {
    return Future.value(
      const FailureResult<TractorHead>(
        PermissionFailure(
          code: FailureCodes.permissionFleetManagement,
          message: 'Fleet management is not allowed.',
        ),
      ),
    );
  }
  return action(
    companyId: context.companyId,
    id: params.id,
    actorRole: context.role.value,
  );
}

Future<Result<TrailerEntity>> _changeTrailerStatus(
  FleetAssetStatusParams params,
  Future<Result<TrailerEntity>> Function({
    required String companyId,
    required String id,
    required String actorRole,
  })
  action,
) {
  final context = params.currentCompanyContext;
  if (!FleetPermissionPolicy.canManageFleet(context.role)) {
    return Future.value(
      const FailureResult<TrailerEntity>(
        PermissionFailure(
          code: FailureCodes.permissionFleetManagement,
          message: 'Fleet management is not allowed.',
        ),
      ),
    );
  }
  return action(
    companyId: context.companyId,
    id: params.id,
    actorRole: context.role.value,
  );
}

String? _normalizeOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
