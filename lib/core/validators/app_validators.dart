abstract final class AppValidators {
  static final RegExp _emailPattern =
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool hasRequiredText(String? value) {
    return value?.trim().isNotEmpty ?? false;
  }

  static bool hasValidEmail(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return false;
    return _emailPattern.hasMatch(normalized);
  }

  static bool hasValidOptionalEmail(String? value) {
    final normalized = value?.trim();
    return normalized == null ||
        normalized.isEmpty ||
        hasValidEmail(normalized);
  }
}
