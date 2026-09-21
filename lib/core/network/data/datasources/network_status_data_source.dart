import 'package:connectivity_plus/connectivity_plus.dart';

import '../../domain/entities/network_connection_status.dart';

abstract interface class NetworkStatusDataSource {
  Future<NetworkConnectionStatus> getCurrentStatus();

  Stream<NetworkConnectionStatus> watchStatus();
}

final class ConnectivityNetworkStatusDataSource
    implements NetworkStatusDataSource {
  final Connectivity _connectivity;

  ConnectivityNetworkStatusDataSource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<NetworkConnectionStatus> getCurrentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _map(results);
  }

  @override
  Stream<NetworkConnectionStatus> watchStatus() async* {
    yield await getCurrentStatus();
    yield* _connectivity.onConnectivityChanged.map(_map);
  }

  NetworkConnectionStatus _map(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );
    return hasConnection
        ? NetworkConnectionStatus.online
        : NetworkConnectionStatus.offline;
  }
}
