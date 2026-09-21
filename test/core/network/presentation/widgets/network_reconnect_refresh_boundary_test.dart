import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/core/network/presentation/widgets/network_reconnect_refresh_boundary.dart';
import 'package:horus_system/core/utils/result.dart';

void main() {
  testWidgets('initial online state does not remount the workspace', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var mounts = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: _MountProbe(onMount: () => mounts += 1),
      ),
    );
    expect(mounts, 1);

    await cubit.startWatching();
    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pump();

    expect(mounts, 1);
  });

  testWidgets('offline recovery remounts the workspace exactly once', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var mounts = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: _MountProbe(onMount: () => mounts += 1),
      ),
    );
    await cubit.startWatching();

    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pump();
    expect(mounts, 1);

    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pump();
    expect(mounts, 2);

    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pump();
    expect(mounts, 2);
  });

  testWidgets('retry checking state preserves pending reconnect refresh', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var mounts = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: _MountProbe(onMount: () => mounts += 1),
      ),
    );
    await cubit.startWatching();

    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pump();
    await cubit.retry();
    expect(mounts, 1);

    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pump();

    expect(mounts, 2);
  });

  testWidgets('parent workspace selection survives child refresh', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: const _WorkspaceSelectionHarness(),
      ),
    );
    await cubit.startWatching();

    await tester.tap(find.byKey(const Key('select-second')));
    await tester.pump();
    expect(find.text('selected:1'), findsOneWidget);

    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pump();
    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pump();

    expect(find.text('selected:1'), findsOneWidget);
  });
}

NetworkStatusCubit _createCubit(NetworkStatusRepository repository) {
  return NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(repository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(repository),
  );
}

class _TestApp extends StatelessWidget {
  final NetworkStatusCubit cubit;
  final Widget child;

  const _TestApp({
    required this.cubit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        home: Scaffold(
          body: NetworkReconnectRefreshBoundary(child: child),
        ),
      ),
    );
  }
}

class _MountProbe extends StatefulWidget {
  final VoidCallback onMount;

  const _MountProbe({required this.onMount});

  @override
  State<_MountProbe> createState() => _MountProbeState();
}

class _MountProbeState extends State<_MountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _WorkspaceSelectionHarness extends StatefulWidget {
  const _WorkspaceSelectionHarness();

  @override
  State<_WorkspaceSelectionHarness> createState() =>
      _WorkspaceSelectionHarnessState();
}

class _WorkspaceSelectionHarnessState extends State<_WorkspaceSelectionHarness> {
  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('selected:$_selected'),
        FilledButton(
          key: const Key('select-second'),
          onPressed: () => setState(() => _selected = 1),
          child: const Text('Select second'),
        ),
      ],
    );
  }
}

final class _ControllableNetworkStatusRepository
    implements NetworkStatusRepository {
  final _controller =
      StreamController<Result<NetworkConnectionStatus>>.broadcast();

  void addStatus(NetworkConnectionStatus status) {
    _controller.add(Success(status));
  }

  Future<void> close() => _controller.close();

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() async {
    return const Success(NetworkConnectionStatus.online);
  }

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() => _controller.stream;
}
