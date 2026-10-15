abstract final class RealtimeTopics {
  static const customersChangedEvent = 'changed';
  static const customersResource = 'customers';
  static const driversResource = 'drivers';
  static const fleetResource = 'fleet';
  static const fleetLicenseDocumentsResource = 'fleet_license_documents';

  static String customers(String companyId) =>
      'horus:company:$companyId:customers';

  static String drivers(String companyId) => 'horus:company:$companyId:drivers';

  static String fleet(String companyId) => 'horus:company:$companyId:fleet';

  static String fleetLicenseDocuments(String companyId) =>
      'horus:company:$companyId:fleet_license_documents';
}
