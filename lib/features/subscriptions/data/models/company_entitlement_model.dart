import '../../domain/entities/company_entitlement.dart';
import '../../domain/entities/entitlement_feature.dart';
import '../../domain/entities/entitlement_limit.dart';
import '../../domain/entities/entitlement_resource.dart';
import '../constants/entitlement_wire_keys.dart';

/// Parses the protected RPC projection; missing fields never imply access.
final class CompanyEntitlementModel {
  final Map<String, dynamic> _data;

  const CompanyEntitlementModel(this._data);

  CompanyEntitlement toEntity() {
    final limits = _requiredMap(EntitlementWireKeys.limits);
    final enabled = _requiredList(EntitlementWireKeys.enabledFeatures);

    return CompanyEntitlement(
      companyId: _requiredString(EntitlementWireKeys.companyId),
      planCode: _requiredString(EntitlementWireKeys.planCode),
      policyVersion: _requiredInt(EntitlementWireKeys.policyVersion),
      revision: _requiredInt(EntitlementWireKeys.revision),
      effectiveAt: _requiredDate(EntitlementWireKeys.effectiveAt),
      expiresAt: _optionalDate(EntitlementWireKeys.expiresAt),
      status: _parseStatus(_requiredString(EntitlementWireKeys.status)),
      limits: {
        for (final resource in EntitlementResource.values)
          resource: _parseLimit(limits[_resourceKey(resource)]),
      },
      enabledFeatures: enabled.map((item) {
        if (item is! String) throw const FormatException('Invalid feature');
        return _parseFeature(item);
      }).toSet(),
    );
  }

  String _requiredString(String key) {
    final value = _data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid entitlement field: $key');
    }
    return value;
  }

  int _requiredInt(String key) {
    final value = _data[key];
    if (value is! int || value <= 0) {
      throw FormatException('Invalid entitlement field: $key');
    }
    return value;
  }

  DateTime _requiredDate(String key) {
    final value = _data[key];
    if (value is! String) throw FormatException('Missing date: $key');
    return DateTime.parse(value).toUtc();
  }

  DateTime? _optionalDate(String key) {
    final value = _data[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('Invalid date: $key');
    return DateTime.parse(value).toUtc();
  }

  Map<String, dynamic> _requiredMap(String key) {
    final value = _data[key];
    if (value is! Map) throw FormatException('Invalid map: $key');
    return Map<String, dynamic>.from(value);
  }

  List<dynamic> _requiredList(String key) {
    final value = _data[key];
    if (value is! List) throw FormatException('Invalid list: $key');
    return value;
  }

  static EntitlementLimit _parseLimit(Object? value) {
    if (value == 'unlimited') return const EntitlementLimit.unlimited();
    if (value is int && value >= 0) return EntitlementLimit.finite(value);
    throw const FormatException('Missing or invalid resource limit');
  }

  static String _resourceKey(EntitlementResource resource) => switch (resource) {
    EntitlementResource.ownerCreatedCompanies => 'owner_created_companies',
    EntitlementResource.companyUsers => 'company_users',
    EntitlementResource.customers => 'customers',
    EntitlementResource.drivers => 'drivers',
    EntitlementResource.combinedVehicles => 'combined_vehicles',
    EntitlementResource.routes => 'routes',
    EntitlementResource.lifetimeTrips => 'lifetime_trips',
    EntitlementResource.lifetimeInvoices => 'lifetime_invoices',
    EntitlementResource.businessDocuments => 'business_documents',
  };

  static CompanyEntitlementStatus _parseStatus(String value) =>
      switch (value) {
        'active' => CompanyEntitlementStatus.active,
        'suspended' => CompanyEntitlementStatus.suspended,
        'expired' => CompanyEntitlementStatus.expired,
        'revoked' => CompanyEntitlementStatus.revoked,
        _ => throw const FormatException('Unsupported entitlement status'),
      };

  static EntitlementFeature _parseFeature(String value) => switch (value) {
    'company_branding' => EntitlementFeature.companyBranding,
    'invoice_pdf' => EntitlementFeature.invoicePdf,
    'report_pdf' => EntitlementFeature.reportPdf,
    'report_xlsx' => EntitlementFeature.reportXlsx,
    'document_upload' => EntitlementFeature.documentUpload,
    'driver_app' => EntitlementFeature.driverApp,
    'advanced_reports' => EntitlementFeature.advancedReports,
    'maintenance' => EntitlementFeature.maintenance,
    'whatsapp_notifications' => EntitlementFeature.whatsappNotifications,
    _ => throw const FormatException('Unsupported entitlement feature'),
  };
}
