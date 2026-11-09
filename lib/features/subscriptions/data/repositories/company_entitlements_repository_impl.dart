import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_entitlement.dart';
import '../../domain/failures/entitlement_failure_codes.dart';
import '../../domain/repositories/company_entitlements_repository.dart';
import '../datasources/company_entitlements_remote_data_source.dart';
import '../models/company_entitlement_model.dart';

final class CompanyEntitlementsRepositoryImpl
    implements CompanyEntitlementsRepository {
  final CompanyEntitlementsRemoteDataSource _remote;

  const CompanyEntitlementsRepositoryImpl(this._remote);

  @override
  Future<Result<CompanyEntitlement>> getCurrent({
    required String companyId,
  }) async {
    try {
      final payload = await _remote.getCurrent(companyId: companyId);
      if (payload == null) {
        return const FailureResult(
          ServerFailure(code: EntitlementFailureCodes.unavailable),
        );
      }
      final entitlement = CompanyEntitlementModel(payload).toEntity();
      if (entitlement.companyId != companyId) {
        return const FailureResult(
          ServerFailure(code: EntitlementFailureCodes.corrupt),
        );
      }
      return Success(entitlement);
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: EntitlementFailureCodes.permissionDenied),
      );
    } on PostgrestException catch (error) {
      return switch (error.code) {
        '42501' || 'P2850' => const FailureResult(
          PermissionFailure(code: EntitlementFailureCodes.permissionDenied),
        ),
        'P2851' => const FailureResult(
          ServerFailure(code: EntitlementFailureCodes.unavailable),
        ),
        'P2852' => const FailureResult(
          ServerFailure(code: EntitlementFailureCodes.corrupt),
        ),
        _ => const FailureResult(
          ServerFailure(code: EntitlementFailureCodes.unavailable),
        ),
      };
    } on FormatException {
      return const FailureResult(
        ServerFailure(code: EntitlementFailureCodes.corrupt),
      );
    } on ArgumentError {
      return const FailureResult(
        ServerFailure(code: EntitlementFailureCodes.corrupt),
      );
    } catch (_) {
      return const FailureResult(
        UnexpectedFailure(),
      );
    }
  }
}
