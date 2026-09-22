import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/trip_document.dart';
import '../policies/trip_evidence_policy.dart';

final class HasRequiredTripEvidenceParams {
  final List<TripDocument> documents;

  const HasRequiredTripEvidenceParams({required this.documents});
}

final class HasRequiredTripEvidenceUseCase
    implements UseCase<bool, HasRequiredTripEvidenceParams> {
  final TripEvidencePolicy _evidencePolicy;

  const HasRequiredTripEvidenceUseCase({
    TripEvidencePolicy evidencePolicy = const TripEvidencePolicy(),
  }) : _evidencePolicy = evidencePolicy;

  @override
  Future<Result<bool>> call(HasRequiredTripEvidenceParams params) {
    return Future.value(
      Success<bool>(_evidencePolicy.hasRequiredEvidence(params.documents)),
    );
  }
}
