import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class SupabaseClientProvider {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    required Uri url,
    required String publishableKey,
  }) async {
    await Supabase.initialize(
      url: url.toString(),
      publishableKey: publishableKey,
    );
  }
}
