import 'dart:convert';

/// Validates credentials at creation or reset, never at sign-in.
enum PasswordCreationValidation { valid, tooShort, tooLong }

/// H.O.R.U.S Auth contract for the hosted Supabase GoTrue password verifier.
///
/// The server enforces minimum Unicode code points and maximum UTF-8 bytes.
/// Do not trim, normalize, truncate, or otherwise mutate entered passwords.
/// Existing credentials may be shorter and must remain valid for sign-in.
abstract final class PasswordPolicy {
  static const int minimumLength = 15;
  static const int maximumUtf8Bytes = 72;

  static PasswordCreationValidation validateForCreation(String password) {
    if (password.runes.length < minimumLength) {
      return PasswordCreationValidation.tooShort;
    }

    if (utf8.encode(password).length > maximumUtf8Bytes) {
      return PasswordCreationValidation.tooLong;
    }

    return PasswordCreationValidation.valid;
  }

  static bool isValidForCreation(String password) =>
      validateForCreation(password) == PasswordCreationValidation.valid;
}
