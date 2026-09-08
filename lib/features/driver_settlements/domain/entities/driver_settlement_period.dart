import '../../../../core/domain/value_objects/business_date.dart';

class DriverSettlementPeriod {
  final BusinessDate start;
  final BusinessDate end;

  const DriverSettlementPeriod({required this.start, required this.end});

  bool get isValid => !end.isBefore(start);

  bool contains(BusinessDate date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
