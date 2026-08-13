import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';
import 'dashboard_state.dart';

final class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _requestId = 0;

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
  }

  bool _isCurrentRequest(int requestId, CurrentCompanyContext requestContext) {
    final current = _currentCompanyContext;
    return !isClosed &&
        requestId == _requestId &&
        current?.companyId == requestContext.companyId &&
        current?.role == requestContext.role;
  }
}
