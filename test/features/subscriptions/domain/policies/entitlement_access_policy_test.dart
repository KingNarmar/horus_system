import 'package:horus_system/features/subscriptions/domain/entities/company_entitlement.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_feature.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:horus_system/features/subscriptions/domain/policies/entitlement_access_policy.dart';
import 'package:test/test.dart';

CompanyEntitlement _entitlement({
  CompanyEntitlementStatus status = CompanyEntitlementStatus.active,
  DateTime? expiresAt,
  Set<EntitlementFeature> features = const {EntitlementFeature.invoicePdf},
}) {
  return CompanyEntitlement(
    companyId: 'company-1',
    planCode: 'free_starter',
    policyVersion: 1,
    revision: 1,
    effectiveAt: DateTime.utc(2026, 11, 1),
    expiresAt: expiresAt,
    status: status,
    limits: {
      for (final resource in EntitlementResource.values)
        resource: EntitlementLimit.finite(1),
    },
    enabledFeatures: features,
  );
}

void main() {
  final now = DateTime.utc(2026, 11, 9);

  test('indefinite active Starter permits included essential output', () {
    expect(
      EntitlementAccessPolicy.isFeatureEnabled(
        _entitlement(),
        EntitlementFeature.invoicePdf,
        at: now,
      ),
      isTrue,
    );
  });

  test('premium capability is not implied by a free grant', () {
    expect(
      EntitlementAccessPolicy.isFeatureEnabled(
        _entitlement(),
        EntitlementFeature.advancedReports,
        at: now,
      ),
      isFalse,
    );
  });

  test('expired or suspended grants do not enable paid capabilities', () {
    for (final entitlement in [
      _entitlement(status: CompanyEntitlementStatus.suspended),
      _entitlement(expiresAt: now),
      _entitlement(status: CompanyEntitlementStatus.revoked),
    ]) {
      expect(
        EntitlementAccessPolicy.isFeatureEnabled(
          entitlement,
          EntitlementFeature.invoicePdf,
          at: now,
        ),
        isFalse,
      );
    }
  });

  test('future-dated grant is not yet effective', () {
    expect(
      EntitlementAccessPolicy.isEffective(
        _entitlement(),
        at: DateTime.utc(2026, 10, 31),
      ),
      isFalse,
    );
  });

  test('missing resource cannot silently become unlimited', () {
    expect(
      () => CompanyEntitlement(
        companyId: 'company-1',
        planCode: 'free_starter',
        policyVersion: 1,
        revision: 1,
        effectiveAt: now,
        status: CompanyEntitlementStatus.active,
        limits: {EntitlementResource.companyUsers: EntitlementLimit.finite(3)},
        enabledFeatures: const {},
      ),
      throwsArgumentError,
    );
  });

  test('limits are immutable and reject invalid usage', () {
    final grant = _entitlement();
    expect(
      () => grant.limits[EntitlementResource.companyUsers] =
          EntitlementLimit.finite(999),
      throwsUnsupportedError,
    );
    expect(
      grant.limitFor(EntitlementResource.companyUsers).allowsAdditional(
        currentUsage: 1,
      ),
      isFalse,
    );
    expect(
      grant.limitFor(EntitlementResource.companyUsers).allowsAdditional(
        currentUsage: -1,
      ),
      isFalse,
    );
  });
}
