import '../constants/realtime_topics.dart';
import 'company_change_message_decoder.dart';

/// Compatibility wrapper for the original Customers-only pilot decoder.
abstract final class CustomersChangeMessageDecoder {
  static bool isForCompany(
    Map<String, dynamic> envelope, {
    required String companyId,
  }) => CompanyChangeMessageDecoder.isForCompanyAndResource(
    envelope,
    companyId: companyId,
    resource: RealtimeTopics.customersResource,
  );
}
