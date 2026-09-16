import '../../../../core/domain/services/money_input_parser.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_write_data.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trips_repository.dart';
import '../services/trip_commercial_amount_calculator.dart';
import '../value_objects/quantity_tons.dart';
import 'trip_financial_configuration.dart';
import 'trip_usecase_params.dart';
import 'trip_write_validation.dart';

class CreateTripUseCase implements UseCase<TripEntity, CreateTripParams> {
  final TripsRepository _repository;

  const CreateTripUseCase(this._repository);

  @override
  Future<Result<TripEntity>> call(CreateTripParams params) {
    return _createTrip(repository: _repository, params: params);
  }
}

class SaveTripUseCase implements UseCase<TripEntity, SaveTripParams> {
  final TripsRepository _repository;

  const SaveTripUseCase(this._repository);

  @override
  Future<Result<TripEntity>> call(SaveTripParams params) {
    return _saveTrip(repository: _repository, params: params);
  }
}

Future<Result<TripEntity>> _createTrip({
  required TripsRepository repository,
  required CreateTripParams params,
}) async {
  final context = params.currentCompanyContext;

  if (!TripsPermissionPolicy.canManageTrips(context.role)) {
    return const FailureResult<TripEntity>(
      PermissionFailure(
        code: FailureCodes.permissionTripsManagement,
        message: 'Trips management is not allowed.',
      ),
    );
  }

  final validationFailure = validateTripWriteData(
    customerId: params.customerId,
    routeId: params.routeId,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
  );

  if (validationFailure != null) {
    return FailureResult<TripEntity>(validationFailure);
  }

  final financialConfiguration = tripFinancialConfiguration(context);
  final commercialResult = _resolveCommercialWriteValues(
    quantityTonsInput: params.quantityTonsInput,
    agreedFreightRatePerTonInput: params.agreedFreightRatePerTonInput,
    financialConfiguration: financialConfiguration,
  );
  if (commercialResult is FailureResult<_TripCommercialWriteValues>) {
    return FailureResult<TripEntity>(commercialResult.failure);
  }
  final commercialValues = commercialResult.dataOrNull!;

  final duplicateVehicleFailure = await validateVehicleAvailability(
    repository: repository,
    companyId: context.companyId,
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
  );

  if (duplicateVehicleFailure != null) {
    return FailureResult<TripEntity>(duplicateVehicleFailure);
  }

  final data = TripWriteData(
    companyId: context.companyId,
    customerId: params.customerId.trim(),
    routeId: params.routeId.trim(),
    driverId: optionalTripText(params.driverId),
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
    loadingOrderNumber: optionalTripText(params.loadingOrderNumber),
    waybillNumber: optionalTripText(params.waybillNumber),
    quantityTons: commercialValues.quantityTons,
    agreedFreightRatePerTon: commercialValues.agreedFreightRatePerTon,
    commercialAmount: commercialValues.commercialAmount,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
    actualLoadingAt: params.actualLoadingAt,
    actualDeliveryAt: params.actualDeliveryAt,
    notes: optionalTripText(params.notes),
  );

  return repository.createTrip(
    data: data,
    actorRole: context.role.value,
    financialConfiguration: financialConfiguration,
  );
}

Future<Result<TripEntity>> _saveTrip({
  required TripsRepository repository,
  required SaveTripParams params,
}) async {
  final context = params.currentCompanyContext;

  if (!TripsPermissionPolicy.canManageTrips(context.role)) {
    return const FailureResult<TripEntity>(
      PermissionFailure(
        code: FailureCodes.permissionTripsManagement,
        message: 'Trips management is not allowed.',
      ),
    );
  }

  final id = optionalTripText(params.id);
  if (id == null) {
    return const FailureResult<TripEntity>(
      ValidationFailure(
        code: FailureCodes.validationTripIdRequired,
        message: 'Trip id is required.',
      ),
    );
  }

  final validationFailure = validateTripWriteData(
    customerId: params.customerId,
    routeId: params.routeId,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
  );

  if (validationFailure != null) {
    return FailureResult<TripEntity>(validationFailure);
  }

  final financialConfiguration = tripFinancialConfiguration(context);
  final existingResult = await repository.getTripDetails(
    companyId: context.companyId,
    id: id,
    financialConfiguration: financialConfiguration,
  );
  if (existingResult is FailureResult<TripEntity>) {
    return FailureResult<TripEntity>(existingResult.failure);
  }
  final existingTrip = existingResult.dataOrNull!;

  final commercialResult = _resolveCommercialWriteValues(
    quantityTonsInput: params.quantityTonsInput,
    agreedFreightRatePerTonInput: params.agreedFreightRatePerTonInput,
    financialConfiguration: financialConfiguration,
    existingTrip: existingTrip,
  );
  if (commercialResult is FailureResult<_TripCommercialWriteValues>) {
    return FailureResult<TripEntity>(commercialResult.failure);
  }
  final commercialValues = commercialResult.dataOrNull!;

  final duplicateVehicleFailure = await validateVehicleAvailability(
    repository: repository,
    companyId: context.companyId,
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
    excludingTripId: id,
  );

  if (duplicateVehicleFailure != null) {
    return FailureResult<TripEntity>(duplicateVehicleFailure);
  }

  final data = TripWriteData(
    companyId: context.companyId,
    customerId: params.customerId.trim(),
    routeId: params.routeId.trim(),
    driverId: optionalTripText(params.driverId),
    tractorHeadId: optionalTripText(params.tractorHeadId),
    trailerId: optionalTripText(params.trailerId),
    loadingOrderNumber: optionalTripText(params.loadingOrderNumber),
    waybillNumber: optionalTripText(params.waybillNumber),
    quantityTons: commercialValues.quantityTons,
    agreedFreightRatePerTon: commercialValues.agreedFreightRatePerTon,
    commercialAmount: commercialValues.commercialAmount,
    scheduledLoadingAt: params.scheduledLoadingAt,
    scheduledDeliveryAt: params.scheduledDeliveryAt,
    actualLoadingAt: params.actualLoadingAt,
    actualDeliveryAt: params.actualDeliveryAt,
    notes: optionalTripText(params.notes),
  );

  return repository.saveTrip(
    id: id,
    data: data,
    actorRole: context.role.value,
    financialConfiguration: financialConfiguration,
  );
}

Result<_TripCommercialWriteValues> _resolveCommercialWriteValues({
  required String? quantityTonsInput,
  required String? agreedFreightRatePerTonInput,
  required CurrencyConfiguration? financialConfiguration,
  TripEntity? existingTrip,
}) {
  final quantityInput = optionalTripText(quantityTonsInput);
  final rateInput = optionalTripText(agreedFreightRatePerTonInput);

  if (existingTrip?.hasLegacyCommercialAmount == true && rateInput == null) {
    if (quantityInput == null) {
      return Success(
        _TripCommercialWriteValues(
          quantityTons: existingTrip!.quantityTons,
          agreedFreightRatePerTon: null,
          commercialAmount: existingTrip.commercialAmount,
        ),
      );
    }

    final parsedQuantity = _parsePositiveQuantity(quantityInput);
    if (parsedQuantity == null) {
      return const FailureResult<_TripCommercialWriteValues>(
        ValidationFailure(
          code: FailureCodes.validationTripQuantityInvalid,
          message: 'Trip quantity is invalid.',
        ),
      );
    }

    if (parsedQuantity == existingTrip!.quantityTons) {
      return Success(
        _TripCommercialWriteValues(
          quantityTons: existingTrip.quantityTons,
          agreedFreightRatePerTon: null,
          commercialAmount: existingTrip.commercialAmount,
        ),
      );
    }

    return const FailureResult<_TripCommercialWriteValues>(
      ValidationFailure(
        code: FailureCodes.validationTripCommercialTermsIncomplete,
        message:
            'An agreed freight rate is required to change legacy commercial terms.',
      ),
    );
  }

  if (quantityInput == null && rateInput == null) {
    return const Success(_TripCommercialWriteValues());
  }

  if (quantityInput == null || rateInput == null) {
    return const FailureResult<_TripCommercialWriteValues>(
      ValidationFailure(
        code: FailureCodes.validationTripCommercialTermsIncomplete,
        message: 'Quantity and agreed freight rate must be provided together.',
      ),
    );
  }

  final quantityTons = _parsePositiveQuantity(quantityInput);
  if (quantityTons == null) {
    return const FailureResult<_TripCommercialWriteValues>(
      ValidationFailure(
        code: FailureCodes.validationTripQuantityInvalid,
        message: 'Trip quantity is invalid.',
      ),
    );
  }

  final configuration = financialConfiguration;
  if (configuration == null) {
    return const FailureResult<_TripCommercialWriteValues>(
      ConflictFailure(
        code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        message: 'Company financial settings are not configured.',
      ),
    );
  }

  const moneyInputParser = MoneyInputParser();
  final rateMinorUnits = moneyInputParser.tryParseMinorUnits(
    _normalizeDecimal(rateInput),
    fractionDigits: configuration.fractionDigits,
  );
  if (rateMinorUnits == null) {
    return const FailureResult<_TripCommercialWriteValues>(
      ValidationFailure(
        code: FailureCodes.validationTripFreightRateInvalid,
        message: 'Agreed freight rate per ton is invalid.',
      ),
    );
  }

  final agreedFreightRatePerTon = Money(
    minorUnits: rateMinorUnits,
    currency: configuration.currency,
  );
  const calculator = TripCommercialAmountCalculator();
  final commercialAmount = calculator.tryCalculate(
    quantityTons: quantityTons,
    agreedFreightRatePerTon: agreedFreightRatePerTon,
  );
  if (commercialAmount == null) {
    return const FailureResult<_TripCommercialWriteValues>(
      ValidationFailure(
        code: FailureCodes.validationTripCommercialAmountOverflow,
        message: 'Trip commercial amount is outside the supported range.',
      ),
    );
  }

  return Success(
    _TripCommercialWriteValues(
      quantityTons: quantityTons,
      agreedFreightRatePerTon: agreedFreightRatePerTon,
      commercialAmount: commercialAmount,
    ),
  );
}

QuantityTons? _parsePositiveQuantity(String input) {
  final quantity = QuantityTons.tryParse(_normalizeDecimal(input));
  if (quantity == null || !quantity.isPositive) return null;
  return quantity;
}

String _normalizeDecimal(String value) => value.trim().replaceAll(',', '.');

final class _TripCommercialWriteValues {
  final QuantityTons? quantityTons;
  final Money? agreedFreightRatePerTon;
  final Money? commercialAmount;

  const _TripCommercialWriteValues({
    this.quantityTons,
    this.agreedFreightRatePerTon,
    this.commercialAmount,
  });
}
