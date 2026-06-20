import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/route_entity.dart';
import '../entities/route_write_data.dart';
import '../policies/routes_permission_policy.dart';
import '../repositories/routes_repository.dart';

class GetRoutesParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetRoutesParams({required this.currentCompanyContext});
}

class SaveRouteParams {
  final CurrentCompanyContext currentCompanyContext;
  final String? id;
  final String loadingLocation;
  final String unloadingLocation;
  final String? governorateFrom;
  final String? governorateTo;
  final double? defaultFreightPrice;
  final String? notes;

  const SaveRouteParams({
    required this.currentCompanyContext,
    this.id,
    required this.loadingLocation,
    required this.unloadingLocation,
    this.governorateFrom,
    this.governorateTo,
    this.defaultFreightPrice,
    this.notes,
  });
}

class RouteActiveStateParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;

  const RouteActiveStateParams({
    required this.currentCompanyContext,
    required this.id,
  });
}

class GetRoutesUseCase implements UseCase<List<RouteEntity>, GetRoutesParams> {
  final RoutesRepository _repository;

  const GetRoutesUseCase(this._repository);

  @override
  Future<Result<List<RouteEntity>>> call(GetRoutesParams params) {
    final context = params.currentCompanyContext;

    if (!RoutesPermissionPolicy.canViewRoutes(context.role)) {
      return Future.value(
        const FailureResult<List<RouteEntity>>(
          PermissionFailure(
            code: FailureCodes.permissionRoutesView,
            message: 'Routes access is not allowed.',
          ),
        ),
      );
    }

    return _repository.getRoutes(companyId: context.companyId);
  }
}

class SaveRouteUseCase implements UseCase<RouteEntity, SaveRouteParams> {
  final RoutesRepository _repository;

  const SaveRouteUseCase(this._repository);

  @override
  Future<Result<RouteEntity>> call(SaveRouteParams params) {
    final context = params.currentCompanyContext;

    if (!RoutesPermissionPolicy.canManageRoutes(context.role)) {
      return Future.value(
        const FailureResult<RouteEntity>(
          PermissionFailure(
            code: FailureCodes.permissionRoutesManagement,
            message: 'Routes management is not allowed.',
          ),
        ),
      );
    }

    final loadingLocation = params.loadingLocation.trim();
    if (loadingLocation.isEmpty) {
      return Future.value(
        const FailureResult<RouteEntity>(
          ValidationFailure(
            code: FailureCodes.validationRouteLoadingLocationRequired,
            message: 'Loading location is required.',
          ),
        ),
      );
    }

    final unloadingLocation = params.unloadingLocation.trim();
    if (unloadingLocation.isEmpty) {
      return Future.value(
        const FailureResult<RouteEntity>(
          ValidationFailure(
            code: FailureCodes.validationRouteUnloadingLocationRequired,
            message: 'Unloading location is required.',
          ),
        ),
      );
    }

    final defaultFreightPrice = params.defaultFreightPrice;
    if (defaultFreightPrice != null && defaultFreightPrice < 0) {
      return Future.value(
        const FailureResult<RouteEntity>(
          ValidationFailure(
            code: FailureCodes.validationRouteFreightPriceNegative,
            message: 'Default freight price cannot be negative.',
          ),
        ),
      );
    }

    final data = RouteWriteData(
      companyId: context.companyId,
      loadingLocation: loadingLocation,
      unloadingLocation: unloadingLocation,
      governorateFrom: _optional(params.governorateFrom),
      governorateTo: _optional(params.governorateTo),
      defaultFreightPrice: defaultFreightPrice,
      notes: _optional(params.notes),
    );

    final id = _optional(params.id);
    if (id == null) {
      return _repository.addRoute(data: data, actorRole: context.role.value);
    }

    return _repository.saveRoute(
      id: id,
      data: data,
      actorRole: context.role.value,
    );
  }
}

class DeactivateRouteUseCase
    implements UseCase<RouteEntity, RouteActiveStateParams> {
  final RoutesRepository _repository;

  const DeactivateRouteUseCase(this._repository);

  @override
  Future<Result<RouteEntity>> call(RouteActiveStateParams params) {
    return _changeRouteActiveState(
      params: params,
      action: _repository.deactivateRoute,
    );
  }
}

class ReactivateRouteUseCase
    implements UseCase<RouteEntity, RouteActiveStateParams> {
  final RoutesRepository _repository;

  const ReactivateRouteUseCase(this._repository);

  @override
  Future<Result<RouteEntity>> call(RouteActiveStateParams params) {
    return _changeRouteActiveState(
      params: params,
      action: _repository.reactivateRoute,
    );
  }
}

Future<Result<RouteEntity>> _changeRouteActiveState({
  required RouteActiveStateParams params,
  required Future<Result<RouteEntity>> Function({
    required String companyId,
    required String id,
    required String actorRole,
  })
  action,
}) {
  final context = params.currentCompanyContext;

  if (!RoutesPermissionPolicy.canManageRoutes(context.role)) {
    return Future.value(
      const FailureResult<RouteEntity>(
        PermissionFailure(
          code: FailureCodes.permissionRoutesManagement,
          message: 'Routes management is not allowed.',
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

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
