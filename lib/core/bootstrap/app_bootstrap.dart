import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../config/app_config_policy.dart';
import '../data/supabase/supabase_client_provider.dart';
import '../logging/app_logger.dart';
import 'bootstrap_failure.dart';

abstract final class AppBootstrap {
  static Future<AppBootstrapResult> initialize() async {
    AppLogger.disable();

    try {
      final config = AppConfig.fromCompileTimeEnvironment();
      AppConfigPolicy.validateForBuild(
        config: config,
        isReleaseMode: kReleaseMode,
      );

      AppLogger.configure(enableDebugLogs: config.enableDebugLogs);
      AppLogger.debug('bootstrap.configuration.validated');

      await SupabaseClientProvider.initialize(
        url: config.supabaseUrl,
        publishableKey: config.supabasePublishableKey,
      );

      AppLogger.debug('bootstrap.services.initialized');
      return const AppBootstrapResult.success();
    } on AppConfigException {
      return AppBootstrapResult.failed(
        BootstrapFailureCode.invalidConfiguration,
      );
    } catch (_) {
      AppLogger.debug('bootstrap.services.initialization_failed');
      return AppBootstrapResult.failed(
        BootstrapFailureCode.serviceInitializationFailed,
      );
    }
  }
}
