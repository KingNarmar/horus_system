import '../constants/company_quota_rpc.dart';

/// Validates the shape of the protected server projection before mapping.
final class CompanyQuotaSnapshotModel {
  final Map<String, dynamic> payload;

  const CompanyQuotaSnapshotModel(this.payload);

  Map<String, dynamic> get entitlement {
    final value = payload[CompanyQuotaRpc.entitlement];
    if (value is! Map) throw const FormatException('Invalid quota entitlement');
    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic> get usage {
    final value = payload[CompanyQuotaRpc.usage];
    if (value is! Map) throw const FormatException('Invalid quota usage');
    final map = Map<String, dynamic>.from(value);
    for (final key in [
      CompanyQuotaRpc.companyUsers,
      CompanyQuotaRpc.combinedVehicles,
      CompanyQuotaRpc.customers,
      CompanyQuotaRpc.drivers,
      CompanyQuotaRpc.routes,
    ]) {
      final count = map[key];
      if (count is! int || count < 0) {
        throw const FormatException('Invalid quota count');
      }
    }
    return map;
  }
}
