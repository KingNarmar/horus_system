import '../../domain/entities/company_quota_snapshot.dart';
import '../../domain/entities/company_quota_usage.dart';
import '../../domain/entities/entitlement_resource.dart';
import '../constants/company_quota_rpc.dart';
import '../models/company_entitlement_model.dart';
import '../models/company_quota_snapshot_model.dart';

abstract final class CompanyQuotaMapper {
  static CompanyQuotaSnapshot toEntity(CompanyQuotaSnapshotModel model) {
    final entitlement = CompanyEntitlementModel(model.entitlement).toEntity();
    final usage = model.usage;
    return CompanyQuotaSnapshot(
      entitlement: entitlement,
      usage: {
        EntitlementResource.companyUsers: CompanyQuotaUsage(
          resource: EntitlementResource.companyUsers,
          limit: entitlement.limitFor(EntitlementResource.companyUsers),
          used: usage[CompanyQuotaRpc.companyUsers] as int,
        ),
        EntitlementResource.combinedVehicles: CompanyQuotaUsage(
          resource: EntitlementResource.combinedVehicles,
          limit: entitlement.limitFor(EntitlementResource.combinedVehicles),
          used: usage[CompanyQuotaRpc.combinedVehicles] as int,
        ),
        EntitlementResource.customers: CompanyQuotaUsage(
          resource: EntitlementResource.customers,
          limit: entitlement.limitFor(EntitlementResource.customers),
          used: usage[CompanyQuotaRpc.customers] as int,
        ),
        EntitlementResource.drivers: CompanyQuotaUsage(
          resource: EntitlementResource.drivers,
          limit: entitlement.limitFor(EntitlementResource.drivers),
          used: usage[CompanyQuotaRpc.drivers] as int,
        ),
        EntitlementResource.routes: CompanyQuotaUsage(
          resource: EntitlementResource.routes,
          limit: entitlement.limitFor(EntitlementResource.routes),
          used: usage[CompanyQuotaRpc.routes] as int,
        ),
      },
    );
  }
}
