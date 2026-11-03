/// Rules for newly created or recovered passwords.
///
/// Passwords are not trimmed or transformed. Count Unicode code points rather
/// than UTF-16 code units so supplementary characters are not double-counted.
/// Authentication of existing accounts must not apply this creation policy.
abstract final class PasswordPolicy {
  static const int minimumLength = 15;

  static bool isValidForCreation(String password) =>
      password.runes.length >= minimumLength;
}
