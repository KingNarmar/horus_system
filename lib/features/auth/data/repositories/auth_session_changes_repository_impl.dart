import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/auth_session_change.dart';
import '../../domain/repositories/auth_session_changes_repository.dart';

/// Maps Supabase auth notifications without exposing SDK types to Domain.
final class SupabaseAuthSessionChangesRepository
    implements AuthSessionChangesRepository {
  final SupabaseClient _client;

  const SupabaseAuthSessionChangesRepository(this._client);

  @override
  Stream<AuthSessionChange> watchSessionChanges() => _client
      .auth
      .onAuthStateChange
      .map(
        (data) => switch (data.event) {
          AuthChangeEvent.signedIn => AuthSessionChange.signedIn,
          AuthChangeEvent.signedOut => AuthSessionChange.signedOut,
          AuthChangeEvent.tokenRefreshed => AuthSessionChange.tokenRefreshed,
          _ => null,
        },
      )
      .where((change) => change != null)
      .cast<AuthSessionChange>();
}
