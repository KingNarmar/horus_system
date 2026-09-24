import 'dart:convert';

import 'app_environment.dart';

abstract final class AppConfigKeys {
  static const String appEnvironment = 'APP_ENV';
  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabasePublishableKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const String enableDebugLogs = 'ENABLE_DEBUG_LOGS';
}

const String _compileTimeAppEnvironment = String.fromEnvironment(
  AppConfigKeys.appEnvironment,
);
const String _compileTimeSupabaseUrl = String.fromEnvironment(
  AppConfigKeys.supabaseUrl,
);
const String _compileTimeSupabasePublishableKey = String.fromEnvironment(
  AppConfigKeys.supabasePublishableKey,
);
const bool _compileTimeEnableDebugLogs = bool.fromEnvironment(
  AppConfigKeys.enableDebugLogs,
  defaultValue: false,
);

enum AppConfigFailureCode {
  missingEnvironment,
  invalidEnvironment,
  missingSupabaseUrl,
  invalidSupabaseUrl,
  insecureSupabaseUrl,
  missingSupabasePublishableKey,
  invalidSupabasePublishableKey,
  privilegedSupabaseKeyForbidden,
  debugLoggingNotAllowed,
  releaseBuildRequiresProductionEnvironment,
}

final class AppConfigException implements Exception {
  final AppConfigFailureCode code;

  const AppConfigException(this.code);

  @override
  String toString() => 'AppConfigException(${code.name})';
}

final class AppConfig {
  final AppEnvironment environment;
  final Uri supabaseUrl;
  final String supabasePublishableKey;
  final bool enableDebugLogs;

  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.enableDebugLogs,
  });

  factory AppConfig.fromCompileTimeEnvironment() {
    return AppConfig.fromValues(
      appEnvironment: _compileTimeAppEnvironment,
      supabaseUrl: _compileTimeSupabaseUrl,
      supabasePublishableKey: _compileTimeSupabasePublishableKey,
      enableDebugLogs: _compileTimeEnableDebugLogs,
    );
  }

  factory AppConfig.fromValues({
    required String appEnvironment,
    required String supabaseUrl,
    required String supabasePublishableKey,
    required bool enableDebugLogs,
  }) {
    final environmentValue = appEnvironment.trim();
    if (environmentValue.isEmpty) {
      throw const AppConfigException(
        AppConfigFailureCode.missingEnvironment,
      );
    }

    final environment = AppEnvironment.tryParse(environmentValue);
    if (environment == null) {
      throw const AppConfigException(
        AppConfigFailureCode.invalidEnvironment,
      );
    }

    final supabaseUrlValue = supabaseUrl.trim();
    if (supabaseUrlValue.isEmpty) {
      throw const AppConfigException(
        AppConfigFailureCode.missingSupabaseUrl,
      );
    }

    final parsedSupabaseUrl = Uri.tryParse(supabaseUrlValue);
    final scheme = parsedSupabaseUrl?.scheme.toLowerCase();
    if (parsedSupabaseUrl == null ||
        parsedSupabaseUrl.host.isEmpty ||
        (scheme != 'http' && scheme != 'https')) {
      throw const AppConfigException(
        AppConfigFailureCode.invalidSupabaseUrl,
      );
    }

    if (environment != AppEnvironment.development && scheme != 'https') {
      throw const AppConfigException(
        AppConfigFailureCode.insecureSupabaseUrl,
      );
    }

    final publishableKey = supabasePublishableKey.trim();
    if (publishableKey.isEmpty) {
      throw const AppConfigException(
        AppConfigFailureCode.missingSupabasePublishableKey,
      );
    }

    switch (_classifySupabaseKey(publishableKey)) {
      case _SupabaseKeyKind.publishable:
      case _SupabaseKeyKind.legacyAnon:
        break;
      case _SupabaseKeyKind.privileged:
        throw const AppConfigException(
          AppConfigFailureCode.privilegedSupabaseKeyForbidden,
        );
      case _SupabaseKeyKind.invalid:
        throw const AppConfigException(
          AppConfigFailureCode.invalidSupabasePublishableKey,
        );
    }

    if (enableDebugLogs && environment != AppEnvironment.development) {
      throw const AppConfigException(
        AppConfigFailureCode.debugLoggingNotAllowed,
      );
    }

    return AppConfig._(
      environment: environment,
      supabaseUrl: parsedSupabaseUrl,
      supabasePublishableKey: publishableKey,
      enableDebugLogs: enableDebugLogs,
    );
  }
}

enum _SupabaseKeyKind {
  publishable,
  legacyAnon,
  privileged,
  invalid,
}

_SupabaseKeyKind _classifySupabaseKey(String value) {
  final lowerValue = value.toLowerCase();

  if (lowerValue.startsWith('sb_secret_')) {
    return _SupabaseKeyKind.privileged;
  }

  if (lowerValue.startsWith('sb_publishable_')) {
    return value.length > 'sb_publishable_'.length
        ? _SupabaseKeyKind.publishable
        : _SupabaseKeyKind.invalid;
  }

  final role = _readJwtRole(value);
  if (role == 'service_role') {
    return _SupabaseKeyKind.privileged;
  }
  if (role == 'anon') {
    return _SupabaseKeyKind.legacyAnon;
  }

  return _SupabaseKeyKind.invalid;
}

String? _readJwtRole(String value) {
  final segments = value.split('.');
  if (segments.length != 3) {
    return null;
  }

  try {
    final payloadBytes = base64Url.decode(base64Url.normalize(segments[1]));
    final payload = jsonDecode(utf8.decode(payloadBytes));
    if (payload is Map<String, dynamic>) {
      return payload['role'] as String?;
    }
    if (payload is Map) {
      return payload['role']?.toString();
    }
  } on FormatException {
    return null;
  }

  return null;
}
