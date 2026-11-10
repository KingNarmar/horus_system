import 'entitlement_limit.dart';
import 'entitlement_resource.dart';

/// Server-measured occupancy for a resource with an explicit policy limit.
final class CompanyQuotaUsage {
  final EntitlementResource resource;
  final EntitlementLimit limit;
  final int used;

  CompanyQuotaUsage({
    required this.resource,
    required this.limit,
    required this.used,
  }) {
    if (used < 0) throw ArgumentError.value(used, 'used');
  }

  int? get remaining {
    final max = limit.value;
    if (max == null) return null;
    final available = max - used;
    return available > 0 ? available : 0;
  }

  bool get isOverLimit {
    final max = limit.value;
    return max != null && used > max;
  }

  bool get isAtCapacity => remaining == 0;
}
