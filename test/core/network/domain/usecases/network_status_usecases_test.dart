import 'dart:async';

import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/usecases/usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

void main() {
  test('get network status delegates to repository', () async {
    final repository = _FakeNetworkStatusRepository();
    final useCase = GetNetworkStatusUseCase(repository);

    final result = await useCase(const NoParams());

    expect(result.dataOrNull, NetworkConnectionStatus.online);
    expect(repository.getCalls, 1);
  });

  test('watch network status delegates repository stream', () async {
    final repository = _FakeNetworkStatusRepository();
    final useCase = WatchNetworkStatusUseCase(repository);

    final values = await useCase(const NoParams()).take(2).toList();

    expect(
      values.map((result) => result.dataOrNull),
      [
        NetworkConnectionStatus.online,
        NetworkConnectionStatus.offline,
      ],
    );
    expect(repository.watchCalls, 1);
  });
}

final class _FakeNetworkStatusRepository implements NetworkStatusRepository {
  int getCalls = 0;
  int watchCalls = 0;

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async {
    getCalls += 1;
    return const Success(NetworkConnectionStatus.online);
  }

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() async* {
    watchCalls += 1;
    yield const Success(NetworkConnectionStatus.online);
    yield const Success(NetworkConnectionStatus.offline);
  }
}
