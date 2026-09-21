import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/network_status_cubit.dart';
import '../cubit/network_status_state.dart';

class NetworkReconnectRefreshBoundary extends StatelessWidget {
  final Future<void> Function() onReconnect;
  final Widget child;

  const NetworkReconnectRefreshBoundary({
    required this.onReconnect,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkStatusCubit, NetworkStatusState>(
      listenWhen: (previous, current) =>
          previous.reconnectRevision != current.reconnectRevision,
      listener: (_, _) => unawaited(onReconnect()),
      child: child,
    );
  }
}
