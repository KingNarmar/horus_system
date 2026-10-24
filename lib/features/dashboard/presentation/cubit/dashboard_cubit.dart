import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../../../core/errors/common_failures.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';
import 'dashboard_state.dart';

final class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _requestId = 0;
  bool _realtimeRefreshPending = false;
  bool _realtimeRefreshInProgress = false;

  DashboardCubit(this._getDashboardSummaryUseCase)
    : super(const DashboardInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_requestId;
    emit(const DashboardLoading());

    final result = await _getDashboardSummaryUseCase(
      GetDashboardSummaryParams(currentCompanyContext: currentCompanyContext),
    );

    if (!_isCurrentRequest(requestId, currentCompanyContext)) return;

    result.when(
      success: (summary) => emit(DashboardLoaded(summary)),
      failure: (failure) => emit(DashboardLoadFailure(failure)),
    );
    if (_realtimeRefreshPending) {
      unawaited(refreshFinancialSummaryFromRealtime());
    }
  }

  /// Re-read only an active dashboard without flashing a full-page loader.
  Future<void> refreshFinancialSummaryFromRealtime() async {
    _realtimeRefreshPending = true;
    if (_realtimeRefreshInProgress) return;
    _realtimeRefreshInProgress = true;
    try {
      while (_realtimeRefreshPending && !isClosed) {
        _realtimeRefreshPending = false;
        final context = _currentCompanyContext;
        final current = state;
        if (context == null || current is! DashboardLoaded) {
          _realtimeRefreshPending = true;
          break;
        }
        final requestId = _requestId;
        final result = await _getDashboardSummaryUseCase(
          GetDashboardSummaryParams(currentCompanyContext: context),
        );
        if (!_isCurrentRequest(requestId, context)) return;
        final latest = state;
        if (latest is! DashboardLoaded) {
          _realtimeRefreshPending = true;
          break;
        }
        final failure = result.failureOrNull;
        if (failure != null &&
            (failure is AuthFailure || failure is PermissionFailure)) {
          emit(DashboardLoadFailure(failure));
          break;
        }
        result.when(
          success: (summary) => emit(DashboardLoaded(summary)),
          failure: (failure) => emit(
            DashboardLoaded(latest.summary, realtimeRefreshFailure: failure),
          ),
        );
      }
    } finally {
      _realtimeRefreshInProgress = false;
    }
  }

  bool _isCurrentRequest(int requestId, CurrentCompanyContext requestContext) {
    final current = _currentCompanyContext;
    return !isClosed &&
        requestId == _requestId &&
        current?.companyId == requestContext.companyId &&
        current?.role == requestContext.role;
  }
}
