import '../../../../core/domain/value_objects/money.dart';
import 'customer_statement_movement.dart';

final class CustomerStatementLine {
  final CustomerStatementMovement movement;
  final Money signedAmount;
  final Money runningBalance;

  const CustomerStatementLine({
    required this.movement,
    required this.signedAmount,
    required this.runningBalance,
  });
}
