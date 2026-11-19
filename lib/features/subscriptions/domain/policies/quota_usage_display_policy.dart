import '../entities/company_quota_usage.dart';

/// Presentation-neutral interpretation of an authoritative quota counter.
/// This policy never changes or authorizes server-side quota enforcement.
enum QuotaUsageLevel { normal, nearLimit, atLimit, overLimit, unlimited }

abstract final class QuotaUsageDisplayPolicy {
  /// Four fifths of a finite quota is considered close to capacity.
  static const int nearLimitNumerator = 4;
  static const int nearLimitDenominator = 5;

  static QuotaUsageLevel levelFor(CompanyQuotaUsage usage) {
    final limit = usage.limit.value;
    if (limit == null) return QuotaUsageLevel.unlimited;
    if (usage.used > limit) return QuotaUsageLevel.overLimit;
    if (usage.used == limit) return QuotaUsageLevel.atLimit;
    if (usage.used * nearLimitDenominator >= limit * nearLimitNumerator) {
      return QuotaUsageLevel.nearLimit;
    }
    return QuotaUsageLevel.normal;
  }

  /// A capped visual indicator; over-limit occupancy is still shown in text.
  static double progressFor(CompanyQuotaUsage usage) {
    final limit = usage.limit.value;
    if (limit == null) return 0;
    if (limit == 0) return 1;
    return (usage.used / limit).clamp(0.0, 1.0).toDouble();
  }
}
