import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static bool _debugLoggingEnabled = false;

  static void configure({required bool enableDebugLogs}) {
    _debugLoggingEnabled = kDebugMode && enableDebugLogs;
  }

  static void disable() {
    _debugLoggingEnabled = false;
  }

  static void debug(String event) {
    if (!_debugLoggingEnabled) {
      return;
    }
    debugPrint('[HORUS] $event');
  }
}
