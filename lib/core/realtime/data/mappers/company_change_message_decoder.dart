/// Accept only minimal server-authored reload hints matching the active tenant.
/// No record fields from these untrusted envelopes enter Domain or UI.
abstract final class CompanyChangeMessageDecoder {
  static bool isForCompanyAndResource(
    Map<String, dynamic> envelope, {
    required String companyId,
    required String resource,
  }) {
    final payload = envelope['payload'];
    if (payload is! Map) return false;

    return payload['company_id'] == companyId &&
        payload['resource'] == resource;
  }
}
