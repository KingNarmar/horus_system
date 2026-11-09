import 'package:horus_system/features/subscriptions/data/datasources/company_entitlements_remote_data_source.dart';
import 'package:horus_system/features/subscriptions/data/repositories/company_entitlements_repository_impl.dart';
import 'package:horus_system/features/subscriptions/domain/failures/entitlement_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

final class _Remote implements CompanyEntitlementsRemoteDataSource {
  final Map<String, dynamic>? response;
  final Object? failure;
  String? lastCompanyId;

  _Remote({this.response, this.failure});

  @override
  Future<Map<String, dynamic>?> getCurrent({required String companyId}) async {
    lastCompanyId = companyId;
    if (failure != null) throw failure!;
    return response;
  }
}

void main() {
  test('missing grant becomes a typed safe failure', () async {
    final result = await CompanyEntitlementsRepositoryImpl(
      _Remote(),
    ).getCurrent(companyId: 'company-1');
    expect(result.failureOrNull?.code, EntitlementFailureCodes.unavailable);
  });

  test('server permission denial is a sanitized typed failure', () async {
    final source = _Remote(
      failure: const PostgrestException(
        message: 'private backend detail',
        code: 'P2850',
      ),
    );
    final result = await CompanyEntitlementsRepositoryImpl(
      source,
    ).getCurrent(companyId: 'company-1');

    expect(result.failureOrNull?.code, EntitlementFailureCodes.permissionDenied);
    expect(result.failureOrNull?.message, isNull);
  });

  test('wrong-company projection fails closed', () async {
    final source = _Remote(response: const {'company_id': 'company-other'});
    final result = await CompanyEntitlementsRepositoryImpl(
      source,
    ).getCurrent(companyId: 'company-1');
    expect(source.lastCompanyId, 'company-1');
    expect(result.failureOrNull?.code, EntitlementFailureCodes.corrupt);
  });

  test('malformed projection fails closed', () async {
    final result = await CompanyEntitlementsRepositoryImpl(
      _Remote(response: const {'company_id': 'company-1'}),
    ).getCurrent(companyId: 'company-1');
    expect(result.failureOrNull?.code, EntitlementFailureCodes.corrupt);
  });
}
