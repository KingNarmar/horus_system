import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_state.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

void main() {
  group('NetworkStatusCubit', () {
    test('offline then online increments reconnect revision once', () async {
      final repository = _ControllableNetworkStatusRepository();
      final cubit = _createCubit(repository);
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      final states = <NetworkStatusState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.startWatching();

      repository.addStatus(NetworkConnectionStatus.offline);
      await Future<void>.delayed(Duration.zero);

      repository.addStatus(NetworkConnectionStatus.online);
      await Future<void>.delayed(Duration.zero);

      repository.addStatus(NetworkConnectionStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(states.whereType<NetworkStatusChecking>(), hasLength(1));
      expect(states.whereType<NetworkStatusOffline>(), hasLength(1));

      final onlineStates = states.whereType<NetworkStatusOnline>().toList();
      expect(onlineStates, hasLength(2));
      expect(
        onlineStates.map((state) => state.reconnectRevision),
        everyElement(1),
      );
      expect(cubit.state.reconnectRevision, 1);
    });

    test('initial online state keeps reconnect revision at zero', () async {
      final repository = _ControllableNetworkStatusRepository();
      final cubit = _createCubit(repository);
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      await cubit.startWatching();
      repository.addStatus(NetworkConnectionStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<NetworkStatusOnline>());
      expect(cubit.state.reconnectRevision, 0);
    });

    test('watch failure blocks and marks reconnect refresh pending', () async {
      final repository = _ControllableNetworkStatusRepository();
      final cubit = _createCubit(repository);
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      await cubit.startWatching();
      repository.addResult(
        const FailureResult(
          NetworkFailure(code: FailureCodes.networkStatusUnavailable),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<NetworkStatusFailure>());
      expect(cubit.state.blocksInteraction, isTrue);
      expect(cubit.state.reconnectRevision, 0);

      repository.addStatus(NetworkConnectionStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<NetworkStatusOnline>());
      expect(cubit.state.reconnectRevision, 1);
    });

    test('retry checking preserves pending reconnect refresh', () async {
      final repository = _ControllableNetworkStatusRepository();
      final cubit = _createCubit(repository);
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      await cubit.startWatching();
      repository.addStatus(NetworkConnectionStatus.offline);
      await Future<void>.delayed(Duration.zero);

      await cubit.retry();
      expect(cubit.state, isA<NetworkStatusChecking>());
      expect(cubit.state.reconnectRevision, 0);

      repository.addStatus(NetworkConnectionStatus.online);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<NetworkStatusOnline>());
      expect(cubit.state.reconnectRevision, 1);
    });
  });
}

NetworkStatusCubit _createCubit(NetworkStatusRepository repository) {
  return NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(repository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(repository),
    pollingEnabled: false,
  );
}

final class _ControllableNetworkStatusRepository
    implements NetworkStatusRepository {
  final _controller =
      StreamController<Result<NetworkConnectionStatus>>.broadcast(sync: true);

  void addStatus(NetworkConnectionStatus status) {
    _controller.add(Success(status));
  }

  void addResult(Result<NetworkConnectionStatus> result) {
    _controller.add(result);
  }

  Future<void> close() => _controller.close();

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async {
    return const Success(NetworkConnectionStatus.online);
  }

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() => _controller.stream;
}
