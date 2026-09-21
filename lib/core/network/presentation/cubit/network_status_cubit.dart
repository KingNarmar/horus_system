import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/app_durations.dart';
import '../../../errors/common_failures.dart';
import '../../../errors/failure_codes.dart';
import '../../../usecases/usecase.dart';
import '../../../utils/result.dart';
import '../../domain/entities/network_connection_status.dart';
import '../../domain/usecases/get_network_status_usecase.dart';
import '../../domain/usecases/watch_network_status_usecase.dart';
import 'network_status_state.dart';

final class NetworkStatusCubit extends Cubit<NetworkStatusState> {
  final GetNetworkStatusUseCase _getNetworkStatusUseCase;
  final WatchNetworkStatusUseCase _watchNetworkStatusUseCase;
  final bool _pollingEnabled;

  StreamSubscription<Result<NetworkConnectionStatus>>? _subscription;
  Timer? _pollingTimer;
  var _reconnectRevision = 0;
  var _refreshPending = false;

  NetworkStatusCubit({
    required GetNetworkStatusUseCase getNetworkStatusUseCase,
    required WatchNetworkStatusUseCase watchNetworkStatusUseCase,
    bool? pollingEnabled,
  }) : _getNetworkStatusUseCase = getNetworkStatusUseCase,
       _watchNetworkStatusUseCase = watchNetworkStatusUseCase,
       _pollingEnabled = pollingEnabled ?? _defaultPollingEnabled(),
       super(const NetworkStatusInitial());

  Future<void> startWatching() async {
    await _subscription?.cancel();
    _pollingTimer?.cancel();

    if (!isClosed) {
      emit(NetworkStatusChecking(reconnectRevision: _reconnectRevision));
    }

    _subscription = _watchNetworkStatusUseCase(const NoParams()).listen(
      _handleResult,
      onError: (_, _) {
        if (!isClosed) {
          _markRefreshPending();
          emit(
            NetworkStatusFailure(
              const NetworkFailure(
                code: FailureCodes.networkStatusUnavailable,
              ),
              reconnectRevision: _reconnectRevision,
            ),
          );
        }
      },
    );

    if (_pollingEnabled) {
      _pollingTimer = Timer.periodic(
        AppDurations.networkStatusPollingInterval,
        (_) => unawaited(_refreshSilently()),
      );
    }
  }

  Future<void> retry() => startWatching();

  Future<void> _refreshSilently() async {
    final result = await _getNetworkStatusUseCase(const NoParams());
    _handleResult(result);
  }

  void _handleResult(Result<NetworkConnectionStatus> result) {
    if (isClosed) return;

    final failure = result.failureOrNull;
    if (failure != null) {
      _markRefreshPending();
      emit(
        NetworkStatusFailure(
          failure,
          reconnectRevision: _reconnectRevision,
        ),
      );
      return;
    }

    switch (result.dataOrNull) {
      case NetworkConnectionStatus.online:
        if (_refreshPending) {
          _refreshPending = false;
          _reconnectRevision += 1;
        }
        emit(NetworkStatusOnline(reconnectRevision: _reconnectRevision));
      case NetworkConnectionStatus.offline:
        _markRefreshPending();
        emit(NetworkStatusOffline(reconnectRevision: _reconnectRevision));
      case null:
        _markRefreshPending();
        emit(
          NetworkStatusFailure(
            const NetworkFailure(
              code: FailureCodes.networkStatusUnavailable,
            ),
            reconnectRevision: _reconnectRevision,
          ),
        );
    }
  }

  void _markRefreshPending() {
    _refreshPending = true;
  }

  static bool _defaultPollingEnabled() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
