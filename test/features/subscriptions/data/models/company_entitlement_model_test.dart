import 'package:horus_system/features/subscriptions/data/models/company_entitlement_model.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_feature.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:test/test.dart';

Map<String, dynamic> _payload() => {
  'company_id': 'company-1',
  'plan_code': 'free_starter',
  'policy_version': 1,
  'revision': 1,
  'status': 'active',
  'effective_at': '2026-11-01T00:00:00Z',
  'expires_at': null,
  'limits': <String, dynamic>{
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
};

void main() {
  test('maps the exact frozen Starter policy without unlimited defaults', () {
    final result = CompanyEntitlementModel(_payload()).toEntity();

    expect(result.companyId, 'company-1');
    expect(result.planCode, 'free_starter');
    expect(result.expiresAt, isNull);
    expect(result.limitFor(EntitlementResource.combinedVehicles).value, 6);
    expect(result.limitFor(EntitlementResource.lifetimeTrips).value, 30);
    expect(result.limitFor(EntitlementResource.lifetimeInvoices).value, 10);
    expect(result.enabledFeatures, contains(EntitlementFeature.reportXlsx));
    expect(
      result.enabledFeatures,
      isNot(contains(EntitlementFeature.advancedReports)),
    );
  });

  test('missing limit is rejected instead of treated as unlimited', () {
    final data = _payload();
    (data['limits'] as Map<String, dynamic>).remove('lifetime_trips');
    expect(
      () => CompanyEntitlementModel(data).toEntity(),
      throwsFormatException,
    );
  });

  test('invalid features and negative limits are rejected', () {
    final data = _payload();
    data['enabled_features'] = ['premium_everything'];
    expect(
      () => CompanyEntitlementModel(data).toEntity(),
      throwsFormatException,
    );

    final other = _payload();
    (other['limits'] as Map<String, dynamic>)['customers'] = -1;
    expect(
      () => CompanyEntitlementModel(other).toEntity(),
      throwsFormatException,
    );
  });

  test('unlimited requires an explicit server marker', () {
    final data = _payload();
    (data['limits'] as Map<String, dynamic>)['drivers'] = 'unlimited';
    final model = CompanyEntitlementModel(data).toEntity();
    expect(model.limitFor(EntitlementResource.drivers).isUnlimited, isTrue);
  });
}
