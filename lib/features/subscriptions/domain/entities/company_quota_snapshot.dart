import 'company_entitlement.dart';
import 'company_quota_usage.dart';
import 'entitlement_resource.dart';

/// A tenant-scoped projection of quota usage and the policy that governs it.
///
/// Only resources with implemented authoritative counters may appear in [usage].
final class CompanyQuotaSnapshot {
  final CompanyEntitlement entitlement;
  final Map<EntitlementResource, CompanyQuotaUsage> usage;

  CompanyQuotaSnapshot({
    required this.entitlement,
    required Map<EntitlementResource, CompanyQuotaUsage> usage,
  }) : usage = Map.unmodifiable(usage) {
    for (final resource in const [
      EntitlementResource.companyUsers,
      EntitlementResource.combinedVehicles,
    ]) {
      if (!this.usage.containsKey(resource)) {
        throw ArgumentError.value(resource, 'usage', 'Missing quota counter');
      }
    }
    for (final entry in this.usage.entries) {
      if (entry.key != entry.value.resource ||
          entry.value.limit.value != entitlement.limitFor(entry.key).value) {
        throw ArgumentError.value(entry.key, 'usage', 'Quota policy mismatch');
      }
    }
  }

  CompanyQuotaUsage usageFor(EntitlementResource resource) => usage[resource]!;
}
