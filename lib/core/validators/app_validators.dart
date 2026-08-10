abstract final class AppValidators {
  static bool hasRequiredText(String? value) {
    return value?.trim().isNotEmpty ?? false;
  }
}
