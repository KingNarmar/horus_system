import 'package:horus_system/features/subscriptions/domain/entities/company_quota_usage.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:horus_system/features/subscriptions/domain/policies/quota_usage_display_policy.dart';
import 'package:test/test.dart';

CompanyQuotaUsage _usage(int used, int limit) => CompanyQuotaUsage(
  resource: EntitlementResource.customers,
  limit: EntitlementLimit.finite(limit),
  used: used,
);

void main() {
  test('normal and near-limit use one documented threshold', () {
    expect(
      QuotaUsageDisplayPolicy.levelFor(_usage(3, 5)),
      QuotaUsageLevel.normal,
    );
    expect(
      QuotaUsageDisplayPolicy.levelFor(_usage(4, 5)),
      QuotaUsageLevel.nearLimit,
    );
    expect(QuotaUsageDisplayPolicy.progressFor(_usage(4, 5)), 0.8);
  });

  test('at-limit and historical over-limit are distinct', () {
    expect(
      QuotaUsageDisplayPolicy.levelFor(_usage(5, 5)),
      QuotaUsageLevel.atLimit,
    );
    expect(
      QuotaUsageDisplayPolicy.levelFor(_usage(6, 5)),
      QuotaUsageLevel.overLimit,
    );
    expect(QuotaUsageDisplayPolicy.progressFor(_usage(6, 5)), 1);
  });

  test('zero capacity is already full even with no occupancy', () {
    expect(
      QuotaUsageDisplayPolicy.levelFor(_usage(0, 0)),
      QuotaUsageLevel.atLimit,
    );
    expect(QuotaUsageDisplayPolicy.progressFor(_usage(0, 0)), 1);
  });

  test('unlimited is not accidentally classified as full', () {
    final usage = CompanyQuotaUsage(
      resource: EntitlementResource.customers,
      limit: const EntitlementLimit.unlimited(),
      used: 100,
    );
    expect(QuotaUsageDisplayPolicy.levelFor(usage), QuotaUsageLevel.unlimited);
    expect(QuotaUsageDisplayPolicy.progressFor(usage), 0);
  });
}
