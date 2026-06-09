import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class EnvConfig {
  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabaseAnonKeyKey = 'SUPABASE_' 'ANON_' 'KEY';

  static String get supabaseUrl => dotenv.get(supabaseUrlKey);

  static String get supabaseAnonKey => dotenv.get(supabaseAnonKeyKey);

  static void validate() {
    final missingKeys = <String>[
      if ((dotenv.maybeGet(supabaseUrlKey) ?? '').trim().isEmpty)
        supabaseUrlKey,
      if ((dotenv.maybeGet(supabaseAnonKeyKey) ?? '').trim().isEmpty)
        supabaseAnonKeyKey,
    ];

    if (missingKeys.isNotEmpty) {
      throw StateError(
        'Missing required environment variables: ${missingKeys.join(', ')}',
      );
    }
  }
}
