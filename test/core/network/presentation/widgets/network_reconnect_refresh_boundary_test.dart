import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/network/domain/entities/network_connection_status.dart';
import 'package:horus_system/core/network/domain/repositories/network_status_repository.dart';
import 'package:horus_system/core/network/domain/usecases/get_network_status_usecase.dart';
import 'package:horus_system/core/network/domain/usecases/watch_network_status_usecase.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_cubit.dart';
import 'package:horus_system/core/network/presentation/cubit/network_status_state.dart';
import 'package:horus_system/core/network/presentation/widgets/network_reconnect_refresh_boundary.dart';
import 'package:horus_system/core/utils/result.dart';

void main() {
  testWidgets('initial online state does not remount the workspace', (
    tester,
  ) async {
    final cubit = _TestNetworkStatusCubit();
    addTearDown(cubit.close);
    var mounts = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: _MountProbe(onMount: () => mounts += 1),
      ),
    );
    expect(mounts, 1);

    cubit.emitState(const NetworkStatusOnline());
    await tester.pump();

    expect(mounts, 1);
  });

  testWidgets('offline recovery remounts the workspace exactly once', (
    tester,
  ) async {
    final cubit = _TestNetworkStatusCubit();
    addTearDown(cubit.close);
    var mounts = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: _MountProbe(onMount: () => mounts += 1),
      ),
    );
    expect(mounts, 1);

    cubit.emitState(const NetworkStatusOffline());
    await tester.pump();
    expect(mounts, 1);

    cubit.emitState(const NetworkStatusOnline());
    await tester.pump();
    expect(mounts, 2);

    cubit.emitState(const NetworkStatusOnline());
    await tester.pump();
    expect(mounts, 2);
  });

  testWidgets('checking state preserves pending reconnect refresh', (
    tester,
  ) async {
    final cubit = _TestNetworkStatusCubit();
    addTearDown(cubit.close);
    var mounts = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        child: _MountProbe(onMount: () => mounts += 1),
      ),
    );

    cubit.emitState(const NetworkStatusOffline());
    await tester.pump();

    cubit.emitState(const NetworkStatusChecking());
    await tester.pump();
    expect(mounts, 1);

    cubit.emitState(const NetworkStatusOnline());
    await tester.pump();

    expect(mounts, 2);
  });

  testWidgets('parent workspace selection survives child refresh', (
    tester,
  ) async {
    final cubit = _TestNetworkStatusCubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      _RawTestApp(cubit: cubit, child: const _WorkspaceSelectionHarness()),
    );

    await tester.tap(find.byKey(const Key('select-second')));
    await tester.pump();
    expect(find.text('selected:1'), findsOneWidget);

    cubit.emitState(const NetworkStatusOffline());
    await tester.pump();

    cubit.emitState(const NetworkStatusOnline());
    await tester.pump();

    expect(find.text('selected:1'), findsOneWidget);
    expect(find.text('workspace:1'), findsOneWidget);
  });
}

class _TestNetworkStatusCubit extends NetworkStatusCubit {
  _TestNetworkStatusCubit()
    : super(
        getNetworkStatusUseCase: GetNetworkStatusUseCase(
          const _UnusedNetworkStatusRepository(),
        ),
        watchNetworkStatusUseCase: WatchNetworkStatusUseCase(
          const _UnusedNetworkStatusRepository(),
        ),
      );

  void emitState(NetworkStatusState state) => emit(state);
}

class _TestApp extends StatelessWidget {
  final NetworkStatusCubit cubit;
  final Widget child;

  const _TestApp({required this.cubit, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        home: Scaffold(body: NetworkReconnectRefreshBoundary(child: child)),
      ),
    );
  }
}

class _RawTestApp extends StatelessWidget {
  final NetworkStatusCubit cubit;
  final Widget child;

  const _RawTestApp({required this.cubit, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(home: Scaffold(body: child)),
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

class _WorkspaceSelectionHarnessState
    extends State<_WorkspaceSelectionHarness> {
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
        NetworkReconnectRefreshBoundary(child: Text('workspace:$_selected')),
      ],
    );
  }
}

final class _UnusedNetworkStatusRepository implements NetworkStatusRepository {
  const _UnusedNetworkStatusRepository();

  @override
  Future<Result<NetworkConnectionStatus>> getCurrentStatus() {
    throw UnimplementedError();
  }

  @override
  Stream<Result<NetworkConnectionStatus>> watchStatus() {
    throw UnimplementedError();
  }
}
