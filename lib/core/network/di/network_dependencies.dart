import '../data/datasources/network_status_data_source.dart';
import '../data/repositories/network_status_repository_impl.dart';
import '../domain/usecases/get_network_status_usecase.dart';
import '../domain/usecases/watch_network_status_usecase.dart';
import '../presentation/cubit/network_status_cubit.dart';

abstract final class NetworkDependencies {
  static NetworkStatusCubit createCubit() {
    final dataSource = ConnectivityNetworkStatusDataSource();
    final repository = NetworkStatusRepositoryImpl(dataSource);

    return NetworkStatusCubit(
      getNetworkStatusUseCase: GetNetworkStatusUseCase(repository),
      watchNetworkStatusUseCase: WatchNetworkStatusUseCase(repository),
    );
  }
}
