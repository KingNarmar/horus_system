import 'dart:async';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/failures/company_failure_codes.dart';
import '../../domain/repositories/selected_company_preference_repository.dart';
import '../datasources/selected_company_preference_local_data_source.dart';

/// Isolates local preferences by the *currently authenticated* actor.
/// The caller's ID is checked both before and after asynchronous storage I/O.
final class SelectedCompanyPreferenceRepositoryImpl
    implements SelectedCompanyPreferenceRepository {
  final SelectedCompanyPreferenceLocalDataSource _local;
  final String? Function() _currentUserId;

  Future<void> _lastWrite = Future<void>.value();

  SelectedCompanyPreferenceRepositoryImpl({
    required SelectedCompanyPreferenceLocalDataSource localDataSource,
    required String? Function() currentUserId,
  }) : _local = localDataSource,
       _currentUserId = currentUserId;

  bool _isCurrentActor(String userId) {
    if (userId.trim().isEmpty) return false;
    try {
      return _currentUserId() == userId;
    } catch (_) {
      // An unavailable SDK identity can never authorize a local preference.
      return false;
    }
  }

  @override
  Future<Result<String?>> read(String userId) async {
    if (!_isCurrentActor(userId)) {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    }
    try {
      final companyId = await _local.read(userId);
      if (!_isCurrentActor(userId)) {
        return const FailureResult(
          AuthFailure(code: CompanyFailureCodes.authRequired),
        );
      }
      // Corrupt/unknown IDs are never trusted; the Domain membership policy
      // will reject anything not present in a fresh server response.
      return Success(companyId);
    } catch (_) {
      if (!_isCurrentActor(userId)) {
        return const FailureResult(
          AuthFailure(code: CompanyFailureCodes.authRequired),
        );
      }
      AppLogger.debug('selected_company_preference_read_unavailable');
      return const FailureResult(UnexpectedFailure());
    }
  }

  @override
  Future<Result<void>> save({
    required String userId,
    required String companyId,
  }) async {
    // Serialize overlapping writes, so the last verified explicit switch
    // wins even when the underlying secure storage finishes out of order.
    final previousWrite = _lastWrite;
    final finished = Completer<void>();
    _lastWrite = finished.future;
    try {
      await previousWrite;
      if (!_isCurrentActor(userId)) {
        return const FailureResult(
          AuthFailure(code: CompanyFailureCodes.authRequired),
        );
      }
      if (companyId.trim().isEmpty) {
        return const FailureResult(
          ValidationFailure(code: CompanyFailureCodes.companyNotAvailable),
        );
      }
      await _local.write(userId, companyId);
      if (!_isCurrentActor(userId)) {
        return const FailureResult(
          AuthFailure(code: CompanyFailureCodes.authRequired),
        );
      }
      return const Success<void>(null);
    } catch (_) {
      if (!_isCurrentActor(userId)) {
        return const FailureResult(
          AuthFailure(code: CompanyFailureCodes.authRequired),
        );
      }
      return const FailureResult(UnexpectedFailure());
    } finally {
      finished.complete();
    }
  }
}
