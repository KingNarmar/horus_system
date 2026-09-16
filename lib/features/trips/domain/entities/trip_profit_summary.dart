import '../../../../core/domain/value_objects/money.dart';

final class TripProfitSummary {
  final Money? totalExpenses;
  final Money? netProfit;

  const TripProfitSummary({this.totalExpenses, this.netProfit});
}
