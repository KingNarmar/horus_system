import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_quota_snapshot.dart';
import '../../domain/failures/quota_failure_codes.dart';
import '../../domain/usecases/get_company_quota_usage_usecase.dart';
import 'subscriptions_state.dart';

final class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  final GetCompanyQuotaUsageUseCase _getCompanyQuotaUsageUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;
  bool _replayRefresh = false;

  SubscriptionsCubit({
    required GetCompanyQuotaUsageUseCase getCompanyQuotaUsageUseCase,
  }) : _getCompanyQuotaUsageUseCase = getCompanyQuotaUsageUseCase,
       super(const SubscriptionsInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) {
    _replayRefresh = false;
    return _request(currentCompanyContext);
  }

  /// Refreshes the visible company only, without pretending old values are new.
  /// A change of company or role always discards the previous snapshot.
  Future<void> refresh(CurrentCompanyContext currentCompanyContext) {
    final previous = state;
    if (previous is SubscriptionsLoaded &&
        previous.currentCompanyContext.companyId ==
            currentCompanyContext.companyId &&
        previous.currentCompanyContext.role == currentCompanyContext.role &&
        _currentCompanyContext?.companyId == currentCompanyContext.companyId &&
        _currentCompanyContext?.role == currentCompanyContext.role) {
      if (previous.isRefreshing) {
        _replayRefresh = true;
        return Future.value();
      }
      return _request(currentCompanyContext, previous: previous);
    }
    _replayRefresh = false;
    return _request(currentCompanyContext);
  }

  Future<void> _request(
    CurrentCompanyContext currentCompanyContext, {
    SubscriptionsLoaded? previous,
  }) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;

    if (previous == null) {
      emit(const SubscriptionsLoading());
    } else {
      emit(
        SubscriptionsLoaded(
          currentCompanyContext: currentCompanyContext,
          quota: previous.quota,
          isRefreshing: true,
        ),
      );
    }

    final result = await _getCompanyQuotaUsageUseCase(
      GetCompanyQuotaUsageParams(currentCompanyContext: currentCompanyContext),
    );
    if (isClosed ||
        requestId != _loadRequestId ||
        _currentCompanyContext?.companyId != currentCompanyContext.companyId ||
        _currentCompanyContext?.role != currentCompanyContext.role) {
      return;
    }

    if (result is FailureResult<CompanyQuotaSnapshot>) {
      emit(SubscriptionsFailure(result.failure));
    } else {
      final snapshot = (result as Success<CompanyQuotaSnapshot>).data;
      if (snapshot.entitlement.companyId != currentCompanyContext.companyId) {
        emit(
          const SubscriptionsFailure(
            ServerFailure(code: QuotaFailureCodes.corrupt),
          ),
        );
      } else {
        emit(
          SubscriptionsLoaded(
            currentCompanyContext: currentCompanyContext,
            quota: snapshot,
          ),
        );
      }
    }

    // A mutation may arrive while an earlier read is in flight. Perform one
    // additional authoritative read instead of silently dropping that signal.
    if (_replayRefresh) {
      _replayRefresh = false;
      await refresh(currentCompanyContext);
    }
  }
}
