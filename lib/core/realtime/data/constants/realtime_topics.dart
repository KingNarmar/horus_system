abstract final class RealtimeTopics {
  static const customersChangedEvent = 'changed';
  static const customersResource = 'customers';

  static String customers(String companyId) =>
      'horus:company:$companyId:customers';
}
