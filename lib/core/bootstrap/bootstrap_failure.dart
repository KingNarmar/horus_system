enum BootstrapFailureCode {
  invalidConfiguration,
  serviceInitializationFailed,
}

final class BootstrapFailure {
  final BootstrapFailureCode code;

  const BootstrapFailure(this.code);
}

final class AppBootstrapResult {
  final BootstrapFailure? failure;

  const AppBootstrapResult.success() : failure = null;

  AppBootstrapResult.failed(BootstrapFailureCode code)
      : failure = BootstrapFailure(code);

  bool get isSuccess => failure == null;
}
