import '../../../../core/documents/domain/entities/business_document_reference.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';

final class DriverCompensationRevision {
  final String id;
  final String companyId;
  final String driverId;
  final Money amount;
  final int currencyFractionDigits;
  final BusinessDate effectiveFrom;
  final BusinessDate? effectiveTo;
  final String? contractReference;
  final BusinessDocumentReference? contractDocumentReference;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverCompensationRevision({
    required this.id,
    required this.companyId,
    required this.driverId,
    required this.amount,
    required this.currencyFractionDigits,
    required this.effectiveFrom,
    this.effectiveTo,
    this.contractReference,
    this.contractDocumentReference,
    this.createdAt,
    this.updatedAt,
  });
}
