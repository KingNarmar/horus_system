import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
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
  final String? defaultFreightRatePerTonInput;
  final String? notes;

  const SaveRouteParams({
    required this.currentCompanyContext,
    this.id,
    required this.loadingLocation,
    required this.unloadingLocation,
    this.governorateFrom,
    this.governorateTo,
    this.defaultFreightRatePerTonInput,
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

    return _repository.getRoutes(
      companyId: context.companyId,
      financialConfiguration: _financialConfiguration(context),
    );
  }
}

class SaveRouteUseCase implements UseCase<RouteEntity, SaveRouteParams> {
  final RoutesRepository _repository;
  final MoneyInputParser _moneyInputParser;

  const SaveRouteUseCase(
    this._repository, {
    MoneyInputParser moneyInputParser = const MoneyInputParser(),
  }) : _moneyInputParser = moneyInputParser;

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

    final configuration = _financialConfiguration(context);
    final rateInput = _optional(params.defaultFreightRatePerTonInput);
    Money? defaultFreightRatePerTon;

    if (rateInput != null) {
      if (configuration == null) {
        return Future.value(
          const FailureResult<RouteEntity>(
            ConflictFailure(
              code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
              message: 'Company financial settings are not configured.',
            ),
          ),
        );
      }

      final minorUnits = _moneyInputParser.tryParseMinorUnits(
        rateInput,
        fractionDigits: configuration.fractionDigits,
      );
      if (minorUnits == null) {
        return Future.value(
          const FailureResult<RouteEntity>(
            ValidationFailure(
              code: FailureCodes.validationRouteFreightRateInvalid,
              message: 'Default freight rate per ton is invalid.',
            ),
          ),
        );
      }

      defaultFreightRatePerTon = Money(
        minorUnits: minorUnits,
        currency: configuration.currency,
      );
    }

    final data = RouteWriteData(
      companyId: context.companyId,
      loadingLocation: loadingLocation,
      unloadingLocation: unloadingLocation,
      governorateFrom: _optional(params.governorateFrom),
      governorateTo: _optional(params.governorateTo),
      defaultFreightRatePerTon: defaultFreightRatePerTon,
      notes: _optional(params.notes),
    );

    final id = _optional(params.id);
    if (id == null) {
      return _repository.addRoute(
        data: data,
        financialConfiguration: configuration,
      );
    }

    return _repository.saveRoute(
      id: id,
      data: data,
      financialConfiguration: configuration,
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
    required CurrencyConfiguration? financialConfiguration,
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
    financialConfiguration: _financialConfiguration(context),
  );
}

CurrencyConfiguration? _financialConfiguration(CurrentCompanyContext context) {
  return CurrencyConfiguration.tryCreate(
    currencyCode: context.company.baseCurrencyCode,
    fractionDigits: context.company.baseCurrencyFractionDigits,
  );
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
