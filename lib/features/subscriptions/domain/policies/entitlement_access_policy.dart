import '../entities/company_entitlement.dart';
import '../entities/entitlement_feature.dart';

/// Pure evaluation only. Server-side authorization remains authoritative.
abstract final class EntitlementAccessPolicy {
  static bool isEffective(
    CompanyEntitlement entitlement, {
    required DateTime at,
  }) {
    if (entitlement.status != CompanyEntitlementStatus.active) return false;
    if (at.isBefore(entitlement.effectiveAt)) return false;
    final expiry = entitlement.expiresAt;
    return expiry == null || at.isBefore(expiry);
  }

  static bool isFeatureEnabled(
    CompanyEntitlement entitlement,
    EntitlementFeature feature, {
    required DateTime at,
  }) {
    return isEffective(entitlement, at: at) &&
        entitlement.enabledFeatures.contains(feature);
  }
}
