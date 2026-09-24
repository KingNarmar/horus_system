import 'package:horus_system/core/config/app_config.dart';
import 'package:horus_system/core/config/app_config_policy.dart';
import 'package:horus_system/core/config/app_environment.dart';
import 'package:test/test.dart';

const _legacyAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJyb2xlIjoiYW5vbiJ9.'
    'signature';
const _legacyServiceRoleKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJyb2xlIjoic2VydmljZV9yb2xlIn0.'
    'signature';

void main() {
  group('AppConfig', () {
    test('accepts development config with local HTTP URL', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'development',
        supabaseUrl: 'http://127.0.0.1:54321',
        supabasePublishableKey: 'sb_publishable_test_key',
        enableDebugLogs: true,
      );

      expect(config.environment, AppEnvironment.development);
      expect(config.supabaseUrl.scheme, 'http');
      expect(config.enableDebugLogs, isTrue);
    });

    test('accepts production config with publishable key', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'production',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_test_key',
        enableDebugLogs: false,
      );

      expect(config.environment, AppEnvironment.production);
      expect(config.supabaseUrl.scheme, 'https');
    });

    test('accepts legacy anon client key', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'development',
        supabaseUrl: 'http://127.0.0.1:54321',
        supabasePublishableKey: _legacyAnonKey,
        enableDebugLogs: false,
      );

      expect(config.supabasePublishableKey, _legacyAnonKey);
    });

    test('rejects missing environment', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: '',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_test_key',
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.missingEnvironment,
          ),
        ),
      );
    });

    test('rejects unknown environment', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'qa',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_test_key',
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.invalidEnvironment,
          ),
        ),
      );
    });

    test('rejects malformed Supabase URL', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'not-a-url',
          supabasePublishableKey: 'sb_publishable_test_key',
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.invalidSupabaseUrl,
          ),
        ),
      );
    });

    test('rejects non-HTTPS staging URL', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'http://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_test_key',
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.insecureSupabaseUrl,
          ),
        ),
      );
    });

    test('rejects new Supabase secret key', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_secret_forbidden',
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.privilegedSupabaseKeyForbidden,
          ),
        ),
      );
    });

    test('rejects legacy service-role JWT', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: _legacyServiceRoleKey,
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.privilegedSupabaseKeyForbidden,
          ),
        ),
      );
    });

    test('rejects unknown key shape', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'not-a-client-key',
          enableDebugLogs: false,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.invalidSupabasePublishableKey,
          ),
        ),
      );
    });

    test('rejects debug logging outside development', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb_publishable_test_key',
          enableDebugLogs: true,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.debugLoggingNotAllowed,
          ),
        ),
      );
    });
  });

  group('AppConfigPolicy', () {
    test('release requires production environment', () {
      final stagingConfig = AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://staging.example.supabase.co',
        supabasePublishableKey: 'sb_publishable_test_key',
        enableDebugLogs: false,
      );

      expect(
        () => AppConfigPolicy.validateForBuild(
          config: stagingConfig,
          isReleaseMode: true,
        ),
        throwsA(
          isA<AppConfigException>().having(
            (error) => error.code,
            'code',
            AppConfigFailureCode.releaseBuildRequiresProductionEnvironment,
          ),
        ),
      );
    });

    test('release accepts production environment', () {
      final productionConfig = AppConfig.fromValues(
        appEnvironment: 'production',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'sb_publishable_test_key',
        enableDebugLogs: false,
      );

      expect(
        () => AppConfigPolicy.validateForBuild(
          config: productionConfig,
          isReleaseMode: true,
        ),
        returnsNormally,
      );
    });
  });
}
