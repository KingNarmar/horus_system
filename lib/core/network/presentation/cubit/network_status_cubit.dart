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

  StreamSubscription<Result<NetworkConnectionStatus>>? _subscription;
  Timer? _pollingTimer;

  NetworkStatusCubit({
    required GetNetworkStatusUseCase getNetworkStatusUseCase,
    required WatchNetworkStatusUseCase watchNetworkStatusUseCase,
  }) : _getNetworkStatusUseCase = getNetworkStatusUseCase,
       _watchNetworkStatusUseCase = watchNetworkStatusUseCase,
       super(const NetworkStatusInitial());

  Future<void> startWatching() async {
    await _subscription?.cancel();
    _pollingTimer?.cancel();

    if (!isClosed) {
      emit(const NetworkStatusChecking());
    }

    _subscription = _watchNetworkStatusUseCase(const NoParams()).listen(
      _handleResult,
      onError: (_, __) {
        if (!isClosed) {
          emit(
            const NetworkStatusFailure(
              NetworkFailure(code: FailureCodes.networkStatusUnavailable),
            ),
          );
        }
      },
    );

    if (_shouldPoll) {
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
      emit(NetworkStatusFailure(failure));
      return;
    }

    switch (result.dataOrNull) {
      case NetworkConnectionStatus.online:
        emit(const NetworkStatusOnline());
      case NetworkConnectionStatus.offline:
        emit(const NetworkStatusOffline());
      case null:
        emit(
          const NetworkStatusFailure(
            NetworkFailure(code: FailureCodes.networkStatusUnavailable),
          ),
        );
    }
  }

  bool get _shouldPoll =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _pollingTimer?.cancel();
    return super.close();
  }
}
