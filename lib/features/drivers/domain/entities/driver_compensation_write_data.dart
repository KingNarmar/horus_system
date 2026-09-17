import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';

final class DriverCompensationWriteData {
  final String companyId;
  final String driverId;
  final Money amount;
  final int currencyFractionDigits;
  final BusinessDate effectiveFrom;
  final BusinessDate? effectiveTo;
  final String? contractReference;

  const DriverCompensationWriteData({
    required this.companyId,
    required this.driverId,
    required this.amount,
    required this.currencyFractionDigits,
    required this.effectiveFrom,
    this.effectiveTo,
    this.contractReference,
  });
}
