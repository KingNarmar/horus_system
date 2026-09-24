enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  final String value;

  const AppEnvironment(this.value);

  static AppEnvironment? tryParse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final environment in values) {
      if (environment.value == normalized) {
        return environment;
      }
    }
    return null;
  }
}
