class DriverSettlementPeriod {
  final DateTime start;
  final DateTime end;

  const DriverSettlementPeriod({required this.start, required this.end});

  bool get isValid => !end.isBefore(start);

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
