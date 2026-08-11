import '../../../../core/domain/value_objects/money.dart';

final class PaymentBalance {
  final Money total;
  final Money paid;
  final Money remaining;

  const PaymentBalance({
    required this.total,
    required this.paid,
    required this.remaining,
  });
}
