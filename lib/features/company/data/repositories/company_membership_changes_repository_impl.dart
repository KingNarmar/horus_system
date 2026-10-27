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
  }) async* {
    try {
      await for (final signal in _source.watchChanges(userId: userId)) {
        if (signal == RealtimeChangeSignal.unavailable) {
          yield const FailureResult(
            NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
          );
        } else {
          yield const Success(CompanyMembershipChange.invalidated);
        }
      }
    } catch (_) {
      yield const FailureResult(
        NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
      );
    }
  }
}
