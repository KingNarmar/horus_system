import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_quota_snapshot.dart';
import '../../domain/usecases/get_company_quota_usage_usecase.dart';
import 'subscriptions_state.dart';

final class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  final GetCompanyQuotaUsageUseCase _getCompanyQuotaUsageUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  SubscriptionsCubit({
    required GetCompanyQuotaUsageUseCase getCompanyQuotaUsageUseCase,
  }) : _getCompanyQuotaUsageUseCase = getCompanyQuotaUsageUseCase,
       super(const SubscriptionsInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    emit(const SubscriptionsLoading());

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
      return;
    }

    emit(
      SubscriptionsLoaded(
        currentCompanyContext: currentCompanyContext,
        quota: (result as Success<CompanyQuotaSnapshot>).data,
      ),
    );
  }
}
