import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_subscription.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/usecases/get_available_subscription_plans_usecase.dart';
import '../../domain/usecases/get_current_company_subscription_usecase.dart';
import 'subscriptions_state.dart';

final class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  final GetAvailableSubscriptionPlansUseCase getAvailablePlansUseCase;
  final GetCurrentCompanySubscriptionUseCase getCurrentSubscriptionUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  SubscriptionsCubit({
    required this.getAvailablePlansUseCase,
    required this.getCurrentSubscriptionUseCase,
  }) : super(const SubscriptionsInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;

    emit(const SubscriptionsLoading());

    final plansResult = await getAvailablePlansUseCase(
      GetAvailableSubscriptionPlansParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;

    if (plansResult is FailureResult<List<SubscriptionPlan>>) {
      emit(SubscriptionsFailure(plansResult.failure));
      return;
    }

    final currentResult = await getCurrentSubscriptionUseCase(
      GetCurrentCompanySubscriptionParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;

    if (currentResult is FailureResult<CompanySubscription?>) {
      emit(SubscriptionsFailure(currentResult.failure));
      return;
    }

    emit(
      SubscriptionsLoaded(
        currentCompanyContext: currentCompanyContext,
        plans: (plansResult as Success<List<SubscriptionPlan>>).data,
        currentSubscription:
            (currentResult as Success<CompanySubscription?>).data,
      ),
    );
  }

  bool _isCurrentLoad(int requestId, String companyId) {
    return requestId == _loadRequestId &&
        _currentCompanyContext?.companyId == companyId;
  }
}
