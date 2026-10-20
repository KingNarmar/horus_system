import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/trip_entity.dart';
import '../failures/trip_failure_codes.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trip_financial_terms_repository.dart';
import 'trip_financial_configuration.dart';

final class SetTripFreightRateParams {
  final CurrentCompanyContext currentCompanyContext;
  final TripEntity trip;
  final String agreedFreightRatePerTonInput;

  const SetTripFreightRateParams({
    required this.currentCompanyContext,
    required this.trip,
    required this.agreedFreightRatePerTonInput,
  });
}

final class SetTripFreightRateUseCase
    implements UseCase<TripEntity, SetTripFreightRateParams> {
  final TripFinancialTermsRepository _repository;
  final MoneyInputParser _parser;

  const SetTripFreightRateUseCase(
    this._repository, {
    MoneyInputParser parser = const MoneyInputParser(),
  }) : _parser = parser;

  @override
  Future<Result<TripEntity>> call(SetTripFreightRateParams params) {
    final context = params.currentCompanyContext;
    final trip = params.trip;

    if (!TripsPermissionPolicy.canManageTripFinancialTerms(context.role) ||
        trip.companyId != context.companyId) {
      return Future.value(
        const FailureResult(
          PermissionFailure(
            code: TripFailureCodes.financialTermsPermissionDenied,
          ),
        ),
      );
    }

    if (trip.quantityTons == null || !trip.quantityTons!.isPositive) {
      return Future.value(
        const FailureResult(
          ConflictFailure(code: TripFailureCodes.pricingRequiresQuantity),
        ),
      );
    }

    final expectedUpdatedAt = trip.updatedAt;
    if (expectedUpdatedAt == null) {
      return Future.value(
        const FailureResult(
          ConflictFailure(code: TripFailureCodes.staleFinancialSnapshot),
        ),
      );
    }

    final configuration = tripFinancialConfiguration(context);
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
      params.agreedFreightRatePerTonInput,
      fractionDigits: configuration.fractionDigits,
    );
    if (minorUnits == null) {
      return Future.value(
        const FailureResult(
          ValidationFailure(
            code: FailureCodes.validationTripFreightRateInvalid,
          ),
        ),
      );
    }

    return _repository.setFreightRate(
      companyId: context.companyId,
      tripId: trip.id,
      agreedFreightRatePerTon: Money(
        minorUnits: minorUnits,
        currency: configuration.currency,
      ),
      financialConfiguration: configuration,
      expectedUpdatedAt: expectedUpdatedAt,
    );
  }
}
