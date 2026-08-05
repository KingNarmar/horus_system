final class CompanyBusinessDateModel {
  final DateTime value;

  const CompanyBusinessDateModel(this.value);

  factory CompanyBusinessDateModel.fromValue(Object? rawValue) {
    final rawDate = rawValue?.toString();
    if (rawDate == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(rawDate)) {
      throw const FormatException('Invalid company business date.');
    }

    final parts = rawDate.split('-').map(int.parse).toList(growable: false);
    final parsed = DateTime.utc(parts[0], parts[1], parts[2]);
    if (parsed.year != parts[0] ||
        parsed.month != parts[1] ||
        parsed.day != parts[2]) {
      throw const FormatException('Invalid company business date.');
    }

    return CompanyBusinessDateModel(parsed);
  }
}
