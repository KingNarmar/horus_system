import '../../../utils/result.dart';
import '../entities/network_connection_status.dart';

abstract interface class NetworkStatusRepository {
  Future<Result<NetworkConnectionStatus>> getCurrentStatus();

  Stream<Result<NetworkConnectionStatus>> watchStatus();
}
