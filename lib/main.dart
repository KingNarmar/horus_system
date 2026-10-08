import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/presentation/bootstrap_failure_app.dart';
import 'core/config/app_config.dart';

const bool _compileTimeEnableDevicePreview = bool.fromEnvironment(
  AppConfigKeys.enableDevicePreview,
  defaultValue: true,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapResult = await AppBootstrap.initialize();
  final failure = bootstrapResult.failure;
  if (failure != null) {
    runApp(BootstrapFailureApp(failure: failure));
    return;
  }

  runApp(
    DevicePreview(
      enabled: !kReleaseMode && _compileTimeEnableDevicePreview,
      builder: (_) => const HorusApp(),
    ),
  );
}
