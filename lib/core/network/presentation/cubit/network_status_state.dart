import '../../../errors/failure.dart';

sealed class NetworkStatusState {
  const NetworkStatusState();

  bool get blocksInteraction => this is! NetworkStatusOnline;
}

final class NetworkStatusInitial extends NetworkStatusState {
  const NetworkStatusInitial();
}

final class NetworkStatusChecking extends NetworkStatusState {
  const NetworkStatusChecking();
}

final class NetworkStatusOnline extends NetworkStatusState {
  const NetworkStatusOnline();
}

final class NetworkStatusOffline extends NetworkStatusState {
  const NetworkStatusOffline();
}

final class NetworkStatusFailure extends NetworkStatusState {
  final Failure failure;

  const NetworkStatusFailure(this.failure);
}
