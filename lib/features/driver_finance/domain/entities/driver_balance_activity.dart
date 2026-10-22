import 'driver_balance_activity_entry.dart';
import 'driver_money_balance.dart';

/// One selected driver's source-linked statement after canonical selection.
/// Previous finalized periods are represented by the balance checkpoint.
final class DriverBalanceActivity {
  final DriverMoneyBalance canonicalBalance;
  final List<DriverBalanceActivityEntry> entries;

  DriverBalanceActivity({
    required this.canonicalBalance,
    required List<DriverBalanceActivityEntry> entries,
  }) : entries = List.unmodifiable(entries);
}
