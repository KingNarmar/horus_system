import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/network_status_cubit.dart';
import '../cubit/network_status_state.dart';

class NetworkReconnectRefreshBoundary extends StatefulWidget {
  final Widget child;

  const NetworkReconnectRefreshBoundary({required this.child, super.key});

  @override
  State<NetworkReconnectRefreshBoundary> createState() =>
      _NetworkReconnectRefreshBoundaryState();
}

class _NetworkReconnectRefreshBoundaryState
    extends State<NetworkReconnectRefreshBoundary> {
  var _revision = 0;
  var _refreshPending = false;

  void _handleNetworkState(NetworkStatusState state) {
    if (state is NetworkStatusOffline || state is NetworkStatusFailure) {
      _refreshPending = true;
      return;
    }

    if (state is NetworkStatusOnline && _refreshPending) {
      _refreshPending = false;
      setState(() => _revision += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkStatusCubit, NetworkStatusState>(
      listener: (_, state) => _handleNetworkState(state),
      child: KeyedSubtree(key: ValueKey(_revision), child: widget.child),
    );
  }
}
