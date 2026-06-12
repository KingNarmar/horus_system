abstract class DbTimestamp {
  static String nowUtcIsoString() => DateTime.now().toUtc().toIso8601String();
}
