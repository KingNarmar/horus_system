import 'package:horus_system/features/subscriptions/domain/entities/company_quota_usage.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:test/test.dart';

void main() {
  test(
    'finite limit retains historical over-cap usage without negative space',
    () {
      final usage = CompanyQuotaUsage(
        resource: EntitlementResource.companyUsers,
        limit: EntitlementLimit.finite(3),
        used: 10,
      );
      expect(usage.used, 10);
      expect(usage.remaining, 0);
      expect(usage.isOverLimit, isTrue);
      expect(usage.isAtCapacity, isTrue);
    },
  );

  test('available and exactly full capacity are distinct', () {
    final available = CompanyQuotaUsage(
      resource: EntitlementResource.combinedVehicles,
      limit: EntitlementLimit.finite(6),
      used: 5,
    );
    final full = CompanyQuotaUsage(
      resource: EntitlementResource.combinedVehicles,
      limit: EntitlementLimit.finite(6),
      used: 6,
    );
    expect(available.remaining, 1);
    expect(available.isAtCapacity, isFalse);
    expect(full.remaining, 0);
    expect(full.isAtCapacity, isTrue);
    expect(full.isOverLimit, isFalse);
  });

  test('explicit unlimited is not confused with missing policy', () {
    final usage = CompanyQuotaUsage(
      resource: EntitlementResource.companyUsers,
      limit: const EntitlementLimit.unlimited(),
      used: 12,
    );
    expect(usage.remaining, isNull);
    expect(usage.isAtCapacity, isFalse);
    expect(usage.isOverLimit, isFalse);
  });

  test('negative backend occupancy is invalid', () {
    expect(
      () => CompanyQuotaUsage(
        resource: EntitlementResource.companyUsers,
        limit: EntitlementLimit.finite(3),
        used: -1,
      ),
      throwsArgumentError,
    );
  });
}
