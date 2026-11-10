import 'package:horus_system/features/subscriptions/data/datasources/company_quota_remote_data_source.dart';
import 'package:horus_system/features/subscriptions/data/repositories/company_quota_repository_impl.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

final class _Remote implements CompanyQuotaRemoteDataSource {
  final Map<String, dynamic>? response;
  final Object? error;

  _Remote({this.response, this.error});

  @override
  Future<Map<String, dynamic>?> getUsage({required String companyId}) async {
    if (error != null) throw error!;
    return response;
  }
}

void main() {
  test('missing server projection yields safe typed failure', () async {
    final result = await CompanyQuotaRepositoryImpl(
      _Remote(),
    ).getUsage(companyId: 'company-1');
    expect(result.failureOrNull?.code, QuotaFailureCodes.unavailable);
  });

  test('foreign tenant and malformed server state fail closed', () async {
    final source = _Remote(
      response: {
        'entitlement': {'company_id': 'another-company'},
        'usage': {'company_users': 1, 'combined_vehicles': 0},
      },
    );
    final result = await CompanyQuotaRepositoryImpl(
      source,
    ).getUsage(companyId: 'company-1');
    expect(result.failureOrNull?.code, QuotaFailureCodes.corrupt);
  });

  test('DB role denial never leaks raw message to UI', () async {
    final result = await CompanyQuotaRepositoryImpl(
      _Remote(
        error: const PostgrestException(
          message: 'private schema detail',
          code: 'P2863',
        ),
      ),
    ).getUsage(companyId: 'company-1');
    expect(result.failureOrNull?.code, QuotaFailureCodes.permissionDenied);
    expect(result.failureOrNull?.message, isNull);
  });

  test(
    'backend unavailability stays distinct from permission denial',
    () async {
      final result = await CompanyQuotaRepositoryImpl(
        _Remote(
          error: const PostgrestException(
            message: 'backend state unavailable',
            code: 'P2861',
          ),
        ),
      ).getUsage(companyId: 'company-1');
      expect(result.failureOrNull?.code, QuotaFailureCodes.unavailable);
    },
  );
}
