import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../utils/result.dart';
import '../../domain/entities/company_data_change.dart';
import '../../domain/repositories/company_data_changes_repository.dart';
import '../datasources/company_data_changes_remote_data_source.dart';
import '../models/realtime_change_signal.dart';

final class CompanyDataChangesRepositoryImpl
    implements CompanyDataChangesRepository {
  final CompanyDataChangesRemoteDataSource _dataSource;

  const CompanyDataChangesRepositoryImpl(this._dataSource);

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
  }) async* {
    try {
      await for (final signal in _dataSource.watchCustomers(
        companyId: companyId,
      )) {
        if (signal == RealtimeChangeSignal.unavailable) {
          yield const FailureResult(
            NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
          );
        } else {
          yield Success(
            CompanyDataChange(
              companyId: companyId,
              resource: CompanyDataResource.customers,
            ),
          );
        }
      }
    } catch (_) {
      yield const FailureResult(
        NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
      );
    }
  }
}
