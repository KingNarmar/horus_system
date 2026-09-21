import '../../../errors/failure.dart';

sealed class NetworkStatusState {
  final int reconnectRevision;

  const NetworkStatusState({this.reconnectRevision = 0});

  bool get blocksInteraction => this is! NetworkStatusOnline;
}

final class NetworkStatusInitial extends NetworkStatusState {
  const NetworkStatusInitial({super.reconnectRevision});
}

final class NetworkStatusChecking extends NetworkStatusState {
  const NetworkStatusChecking({super.reconnectRevision});
}

final class NetworkStatusOnline extends NetworkStatusState {
  const NetworkStatusOnline({super.reconnectRevision});
}

final class NetworkStatusOffline extends NetworkStatusState {
  const NetworkStatusOffline({super.reconnectRevision});
}

final class NetworkStatusFailure extends NetworkStatusState {
  final Failure failure;

  const NetworkStatusFailure(
    this.failure, {
    super.reconnectRevision,
  });
}
