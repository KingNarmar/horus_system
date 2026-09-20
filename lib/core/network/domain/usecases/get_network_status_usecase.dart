import '../../../usecases/usecase.dart';
import '../../../utils/result.dart';
import '../entities/network_connection_status.dart';
import '../repositories/network_status_repository.dart';

final class GetNetworkStatusUseCase
    implements UseCase<NetworkConnectionStatus, NoParams> {
  final NetworkStatusRepository _repository;

  const GetNetworkStatusUseCase(this._repository);

  @override
  Future<Result<NetworkConnectionStatus>> call(NoParams params) {
    return _repository.getCurrentStatus();
  }
}
