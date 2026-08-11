import '../../../../core/domain/value_objects/money.dart';

final class Payment {
  final String id;
  final String companyId;
  final String invoiceId;
  final String customerId;
  final String paymentMethodId;
  final DateTime paymentDate;
  final Money amount;
  final String? referenceNumber;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.companyId,
    required this.invoiceId,
    required this.customerId,
    required this.paymentMethodId,
    required this.paymentDate,
    required this.amount,
    this.referenceNumber,
    this.notes,
    this.createdBy,
    required this.createdAt,
  });
}
