import '../entities/expense_attribution.dart';

abstract final class ExpenseAttributionPolicy {
  static bool isAllowed(ExpenseAttribution attribution) {
    if (!attribution.isTripAttributed) return true;

    return attribution.driverId == null &&
        attribution.tractorHeadId == null &&
        attribution.trailerId == null;
  }
}
