import '../../../../core/domain/value_objects/money.dart';
import 'customer_statement_movement_type.dart';

final class CustomerStatementMovement {
  final CustomerStatementMovementType type;
  final String sourceId;
  final DateTime businessDate;
  final DateTime eventTimestamp;
  final Money amount;
  final String? reference;
  final String relatedInvoiceId;

  const CustomerStatementMovement({
    required this.type,
    required this.sourceId,
    required this.businessDate,
    required this.eventTimestamp,
    required this.amount,
    required this.relatedInvoiceId,
    this.reference,
  });
}
