import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/usecases/invoice_params.dart';
import '../../../invoices/domain/usecases/invoice_query_usecases.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/entities/payment.dart';
import '../../domain/policies/payments_permission_policy.dart';
import '../../domain/usecases/get_payments_usecase.dart';
import '../../domain/usecases/payment_params.dart';
import 'payments_state.dart';

final class PaymentsCubit extends Cubit<PaymentsState> {
  final GetPaymentsUseCase getPaymentsUseCase;
  final GetInvoicesUseCase getInvoicesUseCase;
  final GetPaymentMethodsUseCase getPaymentMethodsUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  PaymentsCubit({
    required this.getPaymentsUseCase,
    required this.getInvoicesUseCase,
    required this.getPaymentMethodsUseCase,
  }) : super(const PaymentsInitial());

  Future<void> loadPayments(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    final previousSearch = state is PaymentsLoaded
        ? (state as PaymentsLoaded).searchQuery
        : '';

    emit(const PaymentsLoading());

    final paymentsResult = await getPaymentsUseCase(
      GetPaymentsParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;
    if (paymentsResult is FailureResult<List<Payment>>) {
      emit(PaymentsFailure(paymentsResult.failure));
      return;
    }

    final invoicesResult = await getInvoicesUseCase(
      GetInvoicesParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;
    if (invoicesResult is FailureResult<List<Invoice>>) {
      emit(PaymentsFailure(invoicesResult.failure));
      return;
    }

    final methodsResult = await getPaymentMethodsUseCase(
      GetPaymentMethodsParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;
    if (methodsResult is FailureResult<List<PaymentMethod>>) {
      emit(PaymentsFailure(methodsResult.failure));
      return;
    }

    final payments = (paymentsResult as Success<List<Payment>>).data;
    final invoices = (invoicesResult as Success<List<Invoice>>).data;
    final methods = (methodsResult as Success<List<PaymentMethod>>).data;

    emit(
      PaymentsLoaded(
        currentCompanyContext: currentCompanyContext,
        allPayments: List.unmodifiable(payments),
        invoices: List.unmodifiable(invoices),
        paymentMethods: List.unmodifiable(methods),
        canRegisterPayments: PaymentsPermissionPolicy.canRegisterPayments(
          currentCompanyContext.role,
        ),
        searchQuery: previousSearch,
      ),
    );
  }

  void setSearchQuery(String value) {
    final currentState = state;
    if (currentState is PaymentsLoaded) {
      emit(currentState.copyWith(searchQuery: value));
    }
  }

  Future<void> refresh() async {
    final context = _currentCompanyContext;
    if (!isClosed && context != null) await loadPayments(context);
  }

  bool _isCurrentLoad(int requestId, String companyId) {
    return !isClosed &&
        requestId == _loadRequestId &&
        _currentCompanyContext?.companyId == companyId;
  }
}
