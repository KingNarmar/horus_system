import '../entities/auth_session_change.dart';

abstract interface class AuthSessionChangesRepository {
  Stream<AuthSessionChange> watchSessionChanges();
}
