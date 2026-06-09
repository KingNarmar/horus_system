import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env_config.dart';

abstract final class SupabaseClientProvider {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    EnvConfig.validate();

    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
    );
  }
}
