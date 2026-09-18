import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_document.dart';
import '../entities/trip_entity.dart';
import '../entities/trip_status.dart';
import '../entities/trip_status_history.dart';
import '../failures/trip_failure_codes.dart';
import '../policies/trip_evidence_policy.dart';
import '../policies/trips_permission_policy.dart';
import '../repositories/trip_documents_repository.dart';
import '../repositories/trips_repository.dart';
import 'trip_financial_configuration.dart';
import 'trip_usecase_params.dart';
import 'trip_write_validation.dart';

class UpdateTripStatusUseCase
    implements UseCase<TripEntity, UpdateTripStatusParams> {
  final TripsRepository _repository;
  final TripDocumentsRepository _documentsRepository;
  final TripEvidencePolicy _evidencePolicy;

  const UpdateTripStatusUseCase(
    this._repository,
    this._documentsRepository, {
    TripEvidencePolicy evidencePolicy = const TripEvidencePolicy(),
  }) : _evidencePolicy = evidencePolicy;

  @override
  Future<Result<TripEntity>> call(UpdateTripStatusParams params) async {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canUpdateTripStatus(context.role)) {
      return const FailureResult<TripEntity>(
        PermissionFailure(code: FailureCodes.permissionTripStatusUpdate),
      );
    }

    final id = optionalTripText(params.id);
    if (id == null) {
      return const FailureResult<TripEntity>(
        ValidationFailure(code: FailureCodes.validationTripIdRequired),
      );
    }

    final financialConfiguration = tripFinancialConfiguration(context);
    final currentTripResult = await _repository.getTripDetails(
      companyId: context.companyId,
      id: id,
      financialConfiguration: financialConfiguration,
    );

    if (currentTripResult is FailureResult<TripEntity>) {
      return FailureResult<TripEntity>(currentTripResult.failure);
    }

    final currentTrip = (currentTripResult as Success<TripEntity>).data;

    if (!currentTrip.status.canMoveTo(params.newStatus)) {
      return const FailureResult<TripEntity>(
        ValidationFailure(
          code: FailureCodes.validationTripStatusTransitionInvalid,
        ),
      );
    }

    if (params.newStatus == TripStatus.documentsReceived) {
      final documentsResult = await _documentsRepository.getActiveDocuments(
        companyId: context.companyId,
        tripId: id,
      );
      if (documentsResult is FailureResult<List<TripDocument>>) {
        return FailureResult<TripEntity>(documentsResult.failure);
      }

      if (!_evidencePolicy.hasRequiredEvidence(
        (documentsResult as Success<List<TripDocument>>).data,
      )) {
        return const FailureResult<TripEntity>(
          ConflictFailure(
            code: TripFailureCodes.conflictStatusEvidenceRequired,
          ),
        );
      }
    }

    return _repository.updateTripStatus(
      companyId: context.companyId,
      id: id,
      newStatus: params.newStatus,
      financialConfiguration: financialConfiguration,
      notes: optionalTripText(params.notes),
    );
  }
}

class GetTripStatusHistoryUseCase
    implements UseCase<List<TripStatusHistory>, GetTripStatusHistoryParams> {
  final TripsRepository _repository;

  const GetTripStatusHistoryUseCase(this._repository);

  @override
  Future<Result<List<TripStatusHistory>>> call(
    GetTripStatusHistoryParams params,
  ) {
    final context = params.currentCompanyContext;

    if (!TripsPermissionPolicy.canViewTrips(context.role)) {
      return Future.value(
        const FailureResult<List<TripStatusHistory>>(
          PermissionFailure(code: FailureCodes.permissionTripsView),
        ),
      );
    }

    final tripId = optionalTripText(params.tripId);
    if (tripId == null) {
      return Future.value(
        const FailureResult<List<TripStatusHistory>>(
          ValidationFailure(code: FailureCodes.validationTripIdRequired),
        ),
      );
    }

    return _repository.getTripStatusHistory(
      companyId: context.companyId,
      tripId: tripId,
    );
  }
}
