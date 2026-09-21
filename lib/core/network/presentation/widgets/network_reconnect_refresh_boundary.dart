import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/network_status_cubit.dart';
import '../cubit/network_status_state.dart';

class NetworkReconnectRefreshBoundary extends StatelessWidget {
  final Widget child;

  const NetworkReconnectRefreshBoundary({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NetworkStatusCubit, NetworkStatusState, int>(
      selector: (state) => state.reconnectRevision,
      builder: (_, reconnectRevision) {
        return KeyedSubtree(
          key: ValueKey(reconnectRevision),
          child: child,
        );
      },
    );
  }
}
