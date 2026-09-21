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
  testWidgets('initial online state does not request a reconnect refresh', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var refreshCalls = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        onReconnect: () async => refreshCalls += 1,
        child: const SizedBox.shrink(),
      ),
    );

    await cubit.startWatching();
    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pumpAndSettle();

    expect(refreshCalls, 0);
  });

  testWidgets('offline recovery requests one refresh only', (tester) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var refreshCalls = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        onReconnect: () async => refreshCalls += 1,
        child: const SizedBox.shrink(),
      ),
    );

    await cubit.startWatching();

    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pumpAndSettle();
    expect(refreshCalls, 0);

    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pumpAndSettle();
    expect(refreshCalls, 1);

    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pumpAndSettle();
    expect(refreshCalls, 1);
  });

  testWidgets('reconnect refresh preserves an open dialog and its input', (
    tester,
  ) async {
    final repository = _ControllableNetworkStatusRepository();
    final cubit = _createCubit(repository);
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });
    var refreshCalls = 0;

    await tester.pumpWidget(
      _TestApp(
        cubit: cubit,
        onReconnect: () async => refreshCalls += 1,
        child: const _DialogHost(),
      ),
    );
    await cubit.startWatching();

    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('dialog-input')),
      'keep this value',
    );

    repository.addStatus(NetworkConnectionStatus.offline);
    await tester.pumpAndSettle();
    repository.addStatus(NetworkConnectionStatus.online);
    await tester.pumpAndSettle();

    expect(refreshCalls, 1);
    expect(find.byType(AlertDialog), findsOneWidget);
    final input = tester.widget<TextField>(
      find.byKey(const Key('dialog-input')),
    );
    expect(input.controller?.text, 'keep this value');
  });
}

NetworkStatusCubit _createCubit(NetworkStatusRepository repository) {
  return NetworkStatusCubit(
    getNetworkStatusUseCase: GetNetworkStatusUseCase(repository),
    watchNetworkStatusUseCase: WatchNetworkStatusUseCase(repository),
    pollingEnabled: false,
  );
}

class _TestApp extends StatelessWidget {
  final NetworkStatusCubit cubit;
  final Future<void> Function() onReconnect;
  final Widget child;

  const _TestApp({
    required this.cubit,
    required this.onReconnect,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        home: Scaffold(
          body: NetworkReconnectRefreshBoundary(
            onReconnect: onReconnect,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DialogHost extends StatelessWidget {
  const _DialogHost();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const Key('open-dialog'),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _InputDialog(),
      ),
      child: const Text('Open'),
    );
  }
}

class _InputDialog extends StatefulWidget {
  const _InputDialog();

  @override
  State<_InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<_InputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: TextField(
        key: const Key('dialog-input'),
        controller: _controller,
      ),
    );
  }
}

final class _ControllableNetworkStatusRepository
    implements NetworkStatusRepository {
  final _controller =
      StreamController<Result<NetworkConnectionStatus>>.broadcast(sync: true);

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
