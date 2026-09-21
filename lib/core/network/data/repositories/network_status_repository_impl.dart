import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../utils/result.dart';
import '../../domain/entities/network_connection_status.dart';
import '../../domain/repositories/network_status_repository.dart';
import '../datasources/network_status_data_source.dart';

final class NetworkStatusRepositoryImpl implements NetworkStatusRepository {
  final NetworkStatusDataSource _dataSource;

  const NetworkStatusRepositoryImpl(this._dataSource);

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async {
    try {
      return Success(await _dataSource.getCurrentStatus());
    } catch (_) {
      return const FailureResult(
        NetworkFailure(code: FailureCodes.networkStatusUnavailable),
      );
    }
  }

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() async* {
    try {
      await for (final status in _dataSource.watchStatus()) {
        yield Success(status);
      }
    } catch (_) {
      yield const FailureResult(
        NetworkFailure(code: FailureCodes.networkStatusUnavailable),
      );
    }
  }
}
