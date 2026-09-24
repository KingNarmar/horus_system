import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver_compensation_revision.dart';
import '../entities/driver_compensation_write_data.dart';
import '../failures/driver_compensation_failure_codes.dart';
import '../policies/driver_compensation_period_policy.dart';
import '../repositories/driver_compensation_repository.dart';
import 'driver_compensation_usecase_validation.dart';

final class CreateDriverCompensationRevisionParams {
  final CurrentCompanyContext currentCompanyContext;
  final String driverId;
  final Money amount;
  final BusinessDate effectiveFrom;
  final BusinessDate? effectiveTo;
  final String? contractReference;
  final BusinessDocumentFile? contractDocument;

  const CreateDriverCompensationRevisionParams({
    required this.currentCompanyContext,
    required this.driverId,
    required this.amount,
    required this.effectiveFrom,
    this.effectiveTo,
    this.contractReference,
    this.contractDocument,
  });
}

final class CreateDriverCompensationRevisionUseCase
    implements
        UseCase<
          DriverCompensationRevision,
          CreateDriverCompensationRevisionParams
        > {
  final DriverCompensationRepository _repository;
  final DriverCompensationPeriodPolicy _periodPolicy;

  const CreateDriverCompensationRevisionUseCase(
    this._repository, {
    DriverCompensationPeriodPolicy periodPolicy =
        const DriverCompensationPeriodPolicy(),
  }) : _periodPolicy = periodPolicy;

  @override
  Future<Result<DriverCompensationRevision>> call(
    CreateDriverCompensationRevisionParams params,
  ) async {
    final accessFailure = DriverCompensationUseCaseValidation.validateManage(
      params.currentCompanyContext,
    );
    if (accessFailure != null) return FailureResult(accessFailure);

    final driverFailure = DriverCompensationUseCaseValidation.validateDriverId(
      params.driverId,
    );
    if (driverFailure != null) return FailureResult(driverFailure);

    final configuration =
        DriverCompensationUseCaseValidation.financialConfiguration(
          params.currentCompanyContext,
        );
    if (configuration == null) {
      return FailureResult(
        DriverCompensationUseCaseValidation.financialConfigurationRequiredFailure(),
      );
    }

    if (!params.amount.isPositive) {
      return const FailureResult(
        ValidationFailure(
          code: DriverCompensationFailureCodes.validationAmountPositive,
        ),
      );
    }
    if (params.amount.currency != configuration.currency) {
      return const FailureResult(
        ValidationFailure(
          code: DriverCompensationFailureCodes.validationCurrencyMismatch,
        ),
      );
    }
    if (!_periodPolicy.isValidPeriod(
      effectiveFrom: params.effectiveFrom,
      effectiveTo: params.effectiveTo,
    )) {
      return const FailureResult(
        ValidationFailure(
          code: DriverCompensationFailureCodes.validationEffectivePeriodInvalid,
        ),
      );
    }

    final contractReference =
        DriverCompensationUseCaseValidation.normalizeContractReference(
          params.contractReference,
        );
    if (contractReference != null &&
        contractReference.length >
            DriverCompensationUseCaseValidation.maxContractReferenceLength) {
      return const FailureResult(
        ValidationFailure(
          code:
              DriverCompensationFailureCodes.validationContractReferenceInvalid,
        ),
      );
    }

    final historyResult = await _repository.getHistory(
      companyId: params.currentCompanyContext.companyId,
      driverId: params.driverId.trim(),
    );
    final historyFailure = historyResult.failureOrNull;
    if (historyFailure != null) return FailureResult(historyFailure);

    final history = historyResult.dataOrNull ?? const [];
    if (_periodPolicy.overlapsAny(
      revisions: history,
      effectiveFrom: params.effectiveFrom,
      effectiveTo: params.effectiveTo,
    )) {
      return const FailureResult(
        ConflictFailure(code: DriverCompensationFailureCodes.conflictOverlap),
      );
    }

    return _repository.createRevision(
      data: DriverCompensationWriteData(
        companyId: params.currentCompanyContext.companyId,
        driverId: params.driverId.trim(),
        amount: params.amount,
        currencyFractionDigits: configuration.fractionDigits,
        effectiveFrom: params.effectiveFrom,
        effectiveTo: params.effectiveTo,
        contractReference: contractReference,
      ),
      contractDocument: params.contractDocument,
    );
  }
}
