import '../../../../core/domain/services/money_decimal_codec.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../entities/driver_finance_trip_option.dart';
import '../entities/driver_financial_movement.dart';
import '../entities/driver_financial_movement_type.dart';
import '../entities/driver_financial_movement_write_data.dart';
import '../policies/driver_finance_permission_policy.dart';
import '../repositories/driver_finance_repository.dart';

class GetDriverMovementsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetDriverMovementsParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

class GetDriverTripOptionsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;

  const GetDriverTripOptionsParams({
    required this.currentCompanyContext,
    required this.driverId,
  });
}

class AddDriverAdvanceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final String amount;
  final BusinessDate movementDate;
  final String? notes;

  const AddDriverAdvanceParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
    this.notes,
  });
}

class AddDriverChargeParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final String? tripId;
  final String amount;
  final BusinessDate movementDate;
  final String? notes;

  const AddDriverChargeParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
    this.tripId,
    this.notes,
  });
}

class AddDriverCashReturnParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final String amount;
  final BusinessDate movementDate;
  final String? notes;

  const AddDriverCashReturnParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.movementDate,
    this.notes,
  });
}

class GetDriverMovementsUseCase
    implements
        UseCase<List<DriverFinancialMovement>, GetDriverMovementsParams> {
  final DriverFinanceRepository _repository;

  const GetDriverMovementsUseCase(this._repository);

  @override
  Future<Result<List<DriverFinancialMovement>>> call(
    GetDriverMovementsParams params,
  ) {
    final driverId = _validViewDriverId(
      params.currentCompanyContext,
      params.driverId,
    );
    if (driverId is FailureResult<String>) {
      return Future.value(FailureResult(driverId.failure));
    }

    return _repository.getDriverMovements(
      companyId: params.currentCompanyContext.companyId,
      driverId: (driverId as Success<String>).data,
    );
  }
}

class GetDriverTripOptionsUseCase
    implements
        UseCase<List<DriverFinanceTripOption>, GetDriverTripOptionsParams> {
  final DriverFinanceRepository _repository;

  const GetDriverTripOptionsUseCase(this._repository);

  @override
  Future<Result<List<DriverFinanceTripOption>>> call(
    GetDriverTripOptionsParams params,
  ) {
    final driverId = _validViewDriverId(
      params.currentCompanyContext,
      params.driverId,
    );
    if (driverId is FailureResult<String>) {
      return Future.value(FailureResult(driverId.failure));
    }

    return _repository.getDriverTripOptions(
      companyId: params.currentCompanyContext.companyId,
      driverId: (driverId as Success<String>).data,
      timeZoneId: params.currentCompanyContext.company.businessTimezone ?? '',
    );
  }
}

class AddDriverAdvanceUseCase
    implements UseCase<DriverFinancialMovement, AddDriverAdvanceParams> {
  final DriverFinanceRepository _repository;

  const AddDriverAdvanceUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(AddDriverAdvanceParams params) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: null,
      type: DriverFinancialMovementType.advance,
      amount: params.amount,
      movementDate: params.movementDate,
      notes: params.notes,
    );
  }
}

class AddDriverChargeUseCase
    implements UseCase<DriverFinancialMovement, AddDriverChargeParams> {
  final DriverFinanceRepository _repository;

  const AddDriverChargeUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(AddDriverChargeParams params) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: params.tripId,
      type: DriverFinancialMovementType.driverCharge,
      amount: params.amount,
      movementDate: params.movementDate,
      notes: params.notes,
    );
  }
}

class AddDriverCashReturnUseCase
    implements UseCase<DriverFinancialMovement, AddDriverCashReturnParams> {
  final DriverFinanceRepository _repository;

  const AddDriverCashReturnUseCase(this._repository);

  @override
  Future<Result<DriverFinancialMovement>> call(
    AddDriverCashReturnParams params,
  ) {
    return _addMovement(
      repository: _repository,
      context: params.currentCompanyContext,
      driverId: params.driverId,
      tripId: null,
      type: DriverFinancialMovementType.cashReturn,
      amount: params.amount,
      movementDate: params.movementDate,
      notes: params.notes,
    );
  }
}

Future<Result<DriverFinancialMovement>> _addMovement({
  required DriverFinanceRepository repository,
  required CurrentCompanyContext context,
  required String driverId,
  required String? tripId,
  required DriverFinancialMovementType type,
  required String amount,
  required BusinessDate movementDate,
  required String? notes,
}) {
  final accessFailure = _validateWritableMovementAccess(
    context: context,
    driverId: driverId,
  );
  if (accessFailure != null) {
    return Future.value(FailureResult(accessFailure));
  }

  final configurationResult = _financialConfiguration(context);
  if (configurationResult is FailureResult<CurrencyConfiguration>) {
    return Future.value(FailureResult(configurationResult.failure));
  }
  final configuration =
      (configurationResult as Success<CurrencyConfiguration>).data;
  final money = const MoneyDecimalCodec().tryDecodeNonNegative(
    amount,
    configuration: configuration,
  );
  if (money == null || !money.isPositive) {
    return Future.value(
      const FailureResult(
        ValidationFailure(
          code: FailureCodes.validationDriverFinanceAmountPositive,
          message:
              'Driver financial movement amount must be greater than zero.',
        ),
      ),
    );
  }

  return repository.addDriverMovement(
    data: DriverFinancialMovementWriteData(
      companyId: context.companyId,
      driverId: driverId.trim(),
      tripId: type.canLinkTrip ? _optional(tripId) : null,
      type: type,
      amount: money,
      currencyFractionDigits: configuration.fractionDigits,
      movementDate: movementDate,
      notes: _optional(notes),
    ),
  );
}

Result<String> _validViewDriverId(
  CurrentCompanyContext context,
  String driverId,
) {
  if (!DriverFinancePermissionPolicy.canViewDriverFinance(context.role)) {
    return const FailureResult<String>(
      PermissionFailure(
        code: FailureCodes.permissionDriverFinanceView,
        message: 'Driver finance access is not allowed.',
      ),
    );
  }

  final value = _optional(driverId);
  if (value == null) {
    return const FailureResult<String>(
      ValidationFailure(
        code: FailureCodes.validationDriverIdRequired,
        message: 'Driver id is required.',
      ),
    );
  }

  return Success(value);
}

Failure? _validateWritableMovementAccess({
  required CurrentCompanyContext context,
  required String driverId,
}) {
  if (!DriverFinancePermissionPolicy.canManageDriverFinance(context.role)) {
    return const PermissionFailure(
      code: FailureCodes.permissionDriverFinanceManagement,
      message: 'Driver finance management is not allowed.',
    );
  }

  if (_optional(driverId) == null) {
    return const ValidationFailure(
      code: FailureCodes.validationDriverIdRequired,
      message: 'Driver id is required.',
    );
  }

  return null;
}

Result<CurrencyConfiguration> _financialConfiguration(
  CurrentCompanyContext context,
) {
  final rawCurrencyCode = context.company.baseCurrencyCode;
  final fractionDigits = context.company.baseCurrencyFractionDigits;
  if (rawCurrencyCode == null || fractionDigits == null) {
    return const FailureResult(
      ConflictFailure(
        code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        message: 'Company financial settings are not configured.',
      ),
    );
  }

  final configuration = CurrencyConfiguration.tryCreate(
    currencyCode: rawCurrencyCode,
    fractionDigits: fractionDigits,
  );
  if (configuration != null) return Success(configuration);

  if (fractionDigits < CurrencyConfiguration.minFractionDigits ||
      fractionDigits > CurrencyConfiguration.maxFractionDigits) {
    return const FailureResult(
      ValidationFailure(
        code: CompanyFailureCodes.validationBaseCurrencyFractionDigitsInvalid,
        message: 'Company base currency fraction digits are invalid.',
      ),
    );
  }

  return const FailureResult(
    ValidationFailure(
      code: CompanyFailureCodes.validationBaseCurrencyInvalid,
      message: 'Company base currency is invalid.',
    ),
  );
}

String? _optional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
