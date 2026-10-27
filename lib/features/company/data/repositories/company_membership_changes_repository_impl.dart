import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/realtime/data/models/realtime_change_signal.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_membership_change.dart';
import '../../domain/repositories/company_membership_changes_repository.dart';
import '../datasources/company_membership_changes_remote_data_source.dart';

/// Converts transport outcomes into Domain refresh hints or typed failures.
final class CompanyMembershipChangesRepositoryImpl
    implements CompanyMembershipChangesRepository {
  final CompanyMembershipChangesRemoteDataSource _source;

  const CompanyMembershipChangesRepositoryImpl(this._source);

  @override
  Stream<Result<CompanyMembershipChange>> watchChanges({
    required String userId,
  }) => _source.watchChanges(userId: userId).map((signal) {
    if (signal == RealtimeChangeSignal.unavailable) {
      return const FailureResult<CompanyMembershipChange>(
        NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
      );
    }
    return const Success<CompanyMembershipChange>(
      CompanyMembershipChange.invalidated,
    );
  }).handleError((Object _, StackTrace stack) {
    // Stream failures are converted below, not surfaced as raw SDK errors.
  }).transform(
    StreamTransformer.fromHandlers(
      handleError: (Object _, StackTrace __, sink) {
        sink.add(
          const FailureResult<CompanyMembershipChange>(
            NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
          ),
        );
      },
    ),
  );
}
