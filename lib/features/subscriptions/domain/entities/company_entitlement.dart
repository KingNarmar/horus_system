import 'entitlement_feature.dart';
import 'entitlement_limit.dart';
import 'entitlement_resource.dart';

enum CompanyEntitlementStatus { active, suspended, expired, revoked }

/// The canonical effective, server-authoritative company entitlement.
/// This object never represents a purchase, invoice, or payment.
final class CompanyEntitlement {
  final String companyId;
  final String planCode;
  final int policyVersion;
  final int revision;
  final DateTime effectiveAt;
  final DateTime? expiresAt;
  final CompanyEntitlementStatus status;
  final Map<EntitlementResource, EntitlementLimit> limits;
  final Set<EntitlementFeature> enabledFeatures;

  CompanyEntitlement({
    required this.companyId,
    required this.planCode,
    required this.policyVersion,
    required this.revision,
    required this.effectiveAt,
    required this.status,
    required Map<EntitlementResource, EntitlementLimit> limits,
    required Set<EntitlementFeature> enabledFeatures,
    this.expiresAt,
  }) : limits = Map.unmodifiable(limits),
       enabledFeatures = Set.unmodifiable(enabledFeatures) {
    if (companyId.trim().isEmpty || planCode.trim().isEmpty) {
      throw ArgumentError('Entitlement identity cannot be empty');
    }
    if (policyVersion <= 0 || revision <= 0) {
      throw ArgumentError('Entitlement versions must be positive');
    }
    if (limits.length != EntitlementResource.values.length ||
        !limits.keys.toSet().containsAll(EntitlementResource.values)) {
      throw ArgumentError('Every resource requires an explicit limit');
    }
  }

  EntitlementLimit limitFor(EntitlementResource resource) => limits[resource]!;
}
