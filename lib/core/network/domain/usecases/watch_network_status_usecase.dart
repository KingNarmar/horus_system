import '../../../usecases/usecase.dart';
import '../../../utils/result.dart';
import '../entities/network_connection_status.dart';
import '../repositories/network_status_repository.dart';

final class WatchNetworkStatusUseCase
    implements StreamUseCase<NetworkConnectionStatus, NoParams> {
  final NetworkStatusRepository _repository;

  const WatchNetworkStatusUseCase(this._repository);

  @override
  Stream<Result<NetworkConnectionStatus>> call(NoParams params) {
    return _repository.watchStatus();
  }
}
