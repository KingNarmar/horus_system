import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company_quota_snapshot.dart';
import '../../domain/failures/quota_failure_codes.dart';
import '../../domain/repositories/company_quota_repository.dart';
import '../datasources/company_quota_remote_data_source.dart';
import '../mappers/company_quota_mapper.dart';
import '../models/company_quota_snapshot_model.dart';

final class CompanyQuotaRepositoryImpl implements CompanyQuotaRepository {
  final CompanyQuotaRemoteDataSource _remote;

  const CompanyQuotaRepositoryImpl(this._remote);

  @override
  Future<Result<CompanyQuotaSnapshot>> getUsage({
    required String companyId,
  }) async {
    try {
      final payload = await _remote.getUsage(companyId: companyId);
      if (payload == null) {
        return const FailureResult(
          ServerFailure(code: QuotaFailureCodes.unavailable),
        );
      }
      final snapshot = CompanyQuotaMapper.toEntity(
        CompanyQuotaSnapshotModel(payload),
      );
      if (snapshot.entitlement.companyId != companyId) {
        return const FailureResult(
          ServerFailure(code: QuotaFailureCodes.corrupt),
        );
      }
      return Success(snapshot);
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: QuotaFailureCodes.permissionDenied),
      );
    } on PostgrestException catch (error) {
      return switch (error.code) {
        '42501' || 'P2863' => const FailureResult(
          PermissionFailure(code: QuotaFailureCodes.permissionDenied),
        ),
        'P2861' => const FailureResult(
          ServerFailure(code: QuotaFailureCodes.unavailable),
        ),
        'P2862' || 'P2852' => const FailureResult(
          ServerFailure(code: QuotaFailureCodes.corrupt),
        ),
        _ => const FailureResult(
          ServerFailure(code: QuotaFailureCodes.unavailable),
        ),
      };
    } on FormatException {
      return const FailureResult(
        ServerFailure(code: QuotaFailureCodes.corrupt),
      );
    } on ArgumentError {
      return const FailureResult(
        ServerFailure(code: QuotaFailureCodes.corrupt),
      );
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
