import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/route_entity.dart';
import '../failures/route_failure_codes.dart';
import '../policies/routes_permission_policy.dart';
import '../repositories/route_financial_terms_repository.dart';

final class SetRouteDefaultFreightRateParams {
  final CurrentCompanyContext currentCompanyContext;
  final RouteEntity route;
  final String rateInput;

  const SetRouteDefaultFreightRateParams({
    required this.currentCompanyContext,
    required this.route,
    required this.rateInput,
  });
}

final class SetRouteDefaultFreightRateUseCase
    implements UseCase<RouteEntity, SetRouteDefaultFreightRateParams> {
  final RouteFinancialTermsRepository _repository;
  final MoneyInputParser _parser;

  const SetRouteDefaultFreightRateUseCase(
    this._repository, {
    MoneyInputParser parser = const MoneyInputParser(),
  }) : _parser = parser;

  @override
  Future<Result<RouteEntity>> call(SetRouteDefaultFreightRateParams params) {
    final context = params.currentCompanyContext;
    final route = params.route;
    if (!RoutesPermissionPolicy.canManageRouteFinancialTerms(context.role) ||
        route.companyId != context.companyId) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: RouteFailureCodes.financialTermsPermissionDenied,
          ),
        ),
      );
    }

    final expectedUpdatedAt = route.updatedAt;
    if (expectedUpdatedAt == null) {
      return Future.value(
        const FailureResult(
          ConflictFailure(code: RouteFailureCodes.staleFinancialSnapshot),
        ),
      );
    }

    final configuration = CurrencyConfiguration.tryCreate(
      currencyCode: context.company.baseCurrencyCode,
      fractionDigits: context.company.baseCurrencyFractionDigits,
    );
    if (configuration == null) {
      return Future.value(
        const FailureResult(
          ConflictFailure(
            code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
          ),
        ),
      );
    }

    final minorUnits = _parser.tryParseMinorUnits(
      params.rateInput,
      fractionDigits: configuration.fractionDigits,
    );
    if (minorUnits == null) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            code: FailureCodes.validationRouteFreightRateInvalid,
          ),
        ),
      );
    }

    return _repository.setDefaultFreightRate(
      companyId: context.companyId,
      routeId: route.id,
      rate: Money(minorUnits: minorUnits, currency: configuration.currency),
      financialConfiguration: configuration,
      expectedUpdatedAt: expectedUpdatedAt,
    );
  }
}
