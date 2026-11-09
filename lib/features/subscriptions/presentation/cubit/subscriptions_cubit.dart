import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/company_entitlement.dart';
import '../../domain/usecases/get_company_entitlement_usecase.dart';
import 'subscriptions_state.dart';

final class SubscriptionsCubit extends Cubit<SubscriptionsState> {
  final GetCompanyEntitlementUseCase _getCompanyEntitlementUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  SubscriptionsCubit({
    required GetCompanyEntitlementUseCase getCompanyEntitlementUseCase,
  }) : _getCompanyEntitlementUseCase = getCompanyEntitlementUseCase,
       super(const SubscriptionsInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    emit(const SubscriptionsLoading());

    final result = await _getCompanyEntitlementUseCase(
      GetCompanyEntitlementParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (isClosed ||
        requestId != _loadRequestId ||
        _currentCompanyContext?.companyId != currentCompanyContext.companyId ||
        _currentCompanyContext?.role != currentCompanyContext.role) {
      return;
    }

    if (result is FailureResult<CompanyEntitlement>) {
      emit(SubscriptionsFailure(result.failure));
      return;
    }

    emit(
      SubscriptionsLoaded(
        currentCompanyContext: currentCompanyContext,
        entitlement: (result as Success<CompanyEntitlement>).data,
      ),
    );
  }
}
