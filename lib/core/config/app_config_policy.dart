import 'app_config.dart';
import 'app_environment.dart';

abstract final class AppConfigPolicy {
  static void validateForBuild({
    required AppConfig config,
    required bool isReleaseMode,
  }) {
    if (isReleaseMode && config.environment != AppEnvironment.production) {
      throw const AppConfigException(
        AppConfigFailureCode.releaseBuildRequiresProductionEnvironment,
      );
    }
  }
}
