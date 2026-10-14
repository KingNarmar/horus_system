abstract final class RealtimeTopics {
  static const customersChangedEvent = 'changed';
  static const customersResource = 'customers';
  static const driversResource = 'drivers';

  static String customers(String companyId) =>
      'horus:company:$companyId:customers';

  static String drivers(String companyId) => 'horus:company:$companyId:drivers';
}
