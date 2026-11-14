import 'package:horus_system/features/subscriptions/data/mappers/company_quota_mapper.dart';
import 'package:horus_system/features/subscriptions/data/models/company_quota_snapshot_model.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:test/test.dart';

Map<String, dynamic> _payload() => {
  'entitlement': {
    'company_id': 'company-1',
    'plan_code': 'free_starter',
    'policy_version': 1,
    'revision': 1,
    'status': 'active',
    'effective_at': '2026-11-09T00:00:00Z',
    'expires_at': null,
    'limits': {
      'owner_created_companies': 1,
      'company_users': 3,
      'customers': 10,
      'drivers': 5,
      'combined_vehicles': 6,
      'routes': 10,
      'lifetime_trips': 30,
      'lifetime_invoices': 10,
      'business_documents': 50,
    },
    'enabled_features': [
      'company_branding',
      'invoice_pdf',
      'report_pdf',
      'report_xlsx',
      'document_upload',
    ],
  },
  'usage': <String, dynamic>{
    'company_users': 10,
    'combined_vehicles': 6,
    'customers': 8,
    'drivers': 7,
    'routes': 3,
    'lifetime_trips': 29,
    'lifetime_invoices': 10,
    'business_documents': 49,
  },
};

void main() {
  test('maps server usage and retains historical above-cap rows', () {
    final snapshot = CompanyQuotaMapper.toEntity(
      CompanyQuotaSnapshotModel(_payload()),
    );
    final users = snapshot.usageFor(EntitlementResource.companyUsers);
    final fleet = snapshot.usageFor(EntitlementResource.combinedVehicles);
    expect(users.used, 10);
    expect(users.isOverLimit, isTrue);
    expect(users.remaining, 0);
    expect(fleet.used, 6);
    expect(fleet.isAtCapacity, isTrue);
    expect(snapshot.usageFor(EntitlementResource.customers).used, 8);
    expect(snapshot.usageFor(EntitlementResource.drivers).isOverLimit, isTrue);
    expect(snapshot.usageFor(EntitlementResource.routes).used, 3);
    expect(snapshot.usageFor(EntitlementResource.lifetimeTrips).remaining, 1);
    expect(
      snapshot.usageFor(EntitlementResource.lifetimeInvoices).remaining,
      0,
    );
    expect(
      snapshot.usageFor(EntitlementResource.businessDocuments).remaining,
      1,
    );
    expect(snapshot.entitlement.policyVersion, 1);
  });

  test('missing, negative and noninteger occupancy fail closed', () {
    for (final invalid in [null, -1, '3', 2.5]) {
      final payload = _payload();
      (payload['usage'] as Map<String, dynamic>)['company_users'] = invalid;
      expect(
        () => CompanyQuotaMapper.toEntity(CompanyQuotaSnapshotModel(payload)),
        throwsFormatException,
      );
    }
  });

  test('missing document occupancy fails closed', () {
    final payload = _payload();
    (payload['usage'] as Map<String, dynamic>).remove('business_documents');
    expect(
      () => CompanyQuotaMapper.toEntity(CompanyQuotaSnapshotModel(payload)),
      throwsFormatException,
    );
  });

  test('corrupt entitlement cannot be replaced with default limits', () {
    final payload = _payload();
    (payload['entitlement'] as Map<String, dynamic>).remove('limits');
    expect(
      () => CompanyQuotaMapper.toEntity(CompanyQuotaSnapshotModel(payload)),
      throwsFormatException,
    );
  });
}
