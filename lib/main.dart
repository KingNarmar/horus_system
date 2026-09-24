import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';
import 'core/bootstrap/presentation/bootstrap_failure_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrapResult = await AppBootstrap.initialize();
  final failure = bootstrapResult.failure;
  if (failure != null) {
    runApp(BootstrapFailureApp(failure: failure));
    return;
  }

  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (_) => const HorusApp()),
  );
}
