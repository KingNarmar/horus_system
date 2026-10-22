import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/money.dart';

/// The authoritative transaction source, not a copied financial movement.
enum DriverBalanceActivitySource { financialMovement, tripExpense }

/// Business meaning of an entry contributing to the canonical balance.
enum DriverBalanceActivityKind {
  advance,
  driverCharge,
  cashReturn,
  driverPaidTripExpense,
}

final class DriverBalanceActivityEntry {
  final DriverBalanceActivitySource source;
  final String sourceId;
  final DriverBalanceActivityKind kind;
  final String companyId;
  final String driverId;
  final String? tripId;
  final BusinessDate businessDate;
  final DateTime createdAt;
  final Money amount;
  final String? description;
  final String? notes;

  const DriverBalanceActivityEntry({
    required this.source,
    required this.sourceId,
    required this.kind,
    required this.companyId,
    required this.driverId,
    required this.businessDate,
    required this.createdAt,
    required this.amount,
    this.tripId,
    this.description,
    this.notes,
  }) : assert(sourceId != ''),
       assert(amount.minorUnits > 0);

  /// Namespaces IDs from distinct source relations for stable list identity.
  String get stableId => source.name + ':' + sourceId;

  /// Matches DriverBalanceCalculator's established sign convention.
  /// The canonical balance itself is never calculated by this entity.
  Money get balanceImpact {
    final units = switch (kind) {
      DriverBalanceActivityKind.advance ||
      DriverBalanceActivityKind.driverCharge => -amount.minorUnits,
      DriverBalanceActivityKind.cashReturn ||
      DriverBalanceActivityKind.driverPaidTripExpense => amount.minorUnits,
    };
    return Money(minorUnits: units, currency: amount.currency);
  }
}
