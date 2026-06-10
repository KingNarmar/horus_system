import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabasePublishableKeyKey =
      'SUPABASE_'
      'PUBLISHABLE_'
      'KEY';

  static String get supabaseUrl => dotenv.get(supabaseUrlKey);

  static String get supabasePublishableKey =>
      dotenv.get(supabasePublishableKeyKey);

  static void validate() {
    final missingKeys = <String>[
      if ((dotenv.maybeGet(supabaseUrlKey) ?? '').trim().isEmpty)
        supabaseUrlKey,
      if ((dotenv.maybeGet(supabasePublishableKeyKey) ?? '').trim().isEmpty)
        supabasePublishableKeyKey,
    ];

    if (missingKeys.isNotEmpty) {
      throw StateError(
        'Missing required environment variables: ${missingKeys.join(', ')}',
      );
    }
  }
}
