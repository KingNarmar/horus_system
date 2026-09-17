import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/documents/domain/entities/business_document_access.dart';
import '../../../../core/documents/domain/entities/business_document_file.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../../domain/failures/driver_compensation_failure_codes.dart';
import '../../domain/usecases/attach_driver_compensation_contract_usecase.dart';
import '../../domain/usecases/create_driver_compensation_revision_usecase.dart';
import '../../domain/usecases/end_driver_compensation_revision_usecase.dart';
import '../../domain/usecases/get_driver_compensation_contract_access_usecase.dart';
import '../../domain/usecases/get_driver_compensation_history_usecase.dart';
import '../../domain/usecases/resolve_driver_compensation_for_date_usecase.dart';
import 'driver_compensation_state.dart';

final class DriverCompensationCubit extends Cubit<DriverCompensationState> {
  final GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase;
  final GetDriverCompensationHistoryUseCase getHistoryUseCase;
  final ResolveDriverCompensationForDateUseCase resolveForDateUseCase;
  final CreateDriverCompensationRevisionUseCase createRevisionUseCase;
  final EndDriverCompensationRevisionUseCase endRevisionUseCase;
  final AttachDriverCompensationContractUseCase attachContractUseCase;
  final GetDriverCompensationContractAccessUseCase contractAccessUseCase;

  DriverCompensationCubit({
    required this.getCompanyBusinessDateUseCase,
    required this.getHistoryUseCase,
    required this.resolveForDateUseCase,
    required this.createRevisionUseCase,
    required this.endRevisionUseCase,
    required this.attachContractUseCase,
    required this.contractAccessUseCase,
  }) : super(const DriverCompensationInitial());

  Future<void> loadForDriver({
    required CurrentCompanyContext currentCompanyContext,
    required String driverId,
  }) async {
    emit(DriverCompensationLoading(driverId: driverId));

    final historyResult = await getHistoryUseCase(
      GetDriverCompensationHistoryParams(
        currentCompanyContext: currentCompanyContext,
        driverId: driverId,
      ),
    );
    final historyFailure = historyResult.failureOrNull;
    if (historyFailure != null) {
      emit(DriverCompensationFailure(historyFailure));
      return;
    }

    final businessDateResult = await getCompanyBusinessDateUseCase(
      GetCompanyBusinessDateParams(companyId: currentCompanyContext.companyId),
    );
    final businessDateFailure = businessDateResult.failureOrNull;
    if (businessDateFailure != null) {
      emit(DriverCompensationFailure(businessDateFailure));
      return;
    }
    final businessDate = businessDateResult.dataOrNull;
    if (businessDate == null) {
      emit(
        const DriverCompensationFailure(
          UnexpectedFailure(
            code: DriverCompensationFailureCodes.unexpectedError,
          ),
        ),
      );
      return;
    }

    final resolutionResult = await resolveForDateUseCase(
      ResolveDriverCompensationForDateParams(
        currentCompanyContext: currentCompanyContext,
        driverId: driverId,
        targetDate: businessDate,
      ),
    );

    emit(
      DriverCompensationLoaded(
        currentCompanyContext: currentCompanyContext,
        driverId: driverId,
        businessDate: businessDate,
        history: historyResult.dataOrNull ?? const [],
        currentRevision: resolutionResult.dataOrNull,
        currentResolutionFailure: resolutionResult.failureOrNull,
      ),
    );
  }

  Future<Failure?> createRevision({
    required Money amount,
    required BusinessDate effectiveFrom,
    BusinessDate? effectiveTo,
    String? contractReference,
    BusinessDocumentFile? contractDocument,
  }) async {
    final loaded = state;
    if (loaded is! DriverCompensationLoaded || loaded.isSaving) {
      return const UnexpectedFailure(
        code: DriverCompensationFailureCodes.unexpectedError,
      );
    }

    emit(
      loaded.copyWith(
        isSaving: true,
        clearPendingRevisionId: true,
        clearMutationFailure: true,
      ),
    );

    final result = await createRevisionUseCase(
      CreateDriverCompensationRevisionParams(
        currentCompanyContext: loaded.currentCompanyContext,
        driverId: loaded.driverId,
        amount: amount,
        effectiveFrom: effectiveFrom,
        effectiveTo: effectiveTo,
        contractReference: contractReference,
        contractDocument: contractDocument,
      ),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        loaded.copyWith(
          isSaving: false,
          clearPendingRevisionId: true,
          mutationFailure: failure,
        ),
      );
      return failure;
    }

    await loadForDriver(
      currentCompanyContext: loaded.currentCompanyContext,
      driverId: loaded.driverId,
    );
    return null;
  }

  Future<Failure?> endRevision({
    required DriverCompensationRevision revision,
    required BusinessDate effectiveTo,
  }) async {
    final loaded = state;
    if (loaded is! DriverCompensationLoaded || loaded.isSaving) {
      return const UnexpectedFailure(
        code: DriverCompensationFailureCodes.unexpectedError,
      );
    }

    emit(
      loaded.copyWith(
        isSaving: true,
        pendingRevisionId: revision.id,
        clearMutationFailure: true,
      ),
    );

    final result = await endRevisionUseCase(
      EndDriverCompensationRevisionParams(
        currentCompanyContext: loaded.currentCompanyContext,
        revision: revision,
        effectiveTo: effectiveTo,
      ),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        loaded.copyWith(
          isSaving: false,
          pendingRevisionId: revision.id,
          mutationFailure: failure,
        ),
      );
      return failure;
    }

    await loadForDriver(
      currentCompanyContext: loaded.currentCompanyContext,
      driverId: loaded.driverId,
    );
    return null;
  }

  Future<Failure?> attachContractDocument({
    required DriverCompensationRevision revision,
    required BusinessDocumentFile document,
  }) async {
    final loaded = state;
    if (loaded is! DriverCompensationLoaded || loaded.isSaving) {
      return const UnexpectedFailure(
        code: DriverCompensationFailureCodes.unexpectedError,
      );
    }

    emit(
      loaded.copyWith(
        isSaving: true,
        pendingRevisionId: revision.id,
        clearMutationFailure: true,
      ),
    );

    final result = await attachContractUseCase(
      AttachDriverCompensationContractParams(
        currentCompanyContext: loaded.currentCompanyContext,
        revision: revision,
        document: document,
      ),
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        loaded.copyWith(
          isSaving: false,
          pendingRevisionId: revision.id,
          mutationFailure: failure,
        ),
      );
      return failure;
    }

    await loadForDriver(
      currentCompanyContext: loaded.currentCompanyContext,
      driverId: loaded.driverId,
    );
    return null;
  }

  Future<Result<BusinessDocumentAccess>> createContractAccess(
    DriverCompensationRevision revision,
  ) {
    final loaded = state;
    if (loaded is! DriverCompensationLoaded) {
      return Future.value(
        const FailureResult(
          UnexpectedFailure(
            code: DriverCompensationFailureCodes.unexpectedError,
          ),
        ),
      );
    }

    return contractAccessUseCase(
      GetDriverCompensationContractAccessParams(
        currentCompanyContext: loaded.currentCompanyContext,
        revision: revision,
      ),
    );
  }

  void clear() {
    emit(const DriverCompensationInitial());
  }
}
