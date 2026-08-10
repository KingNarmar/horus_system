import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/usecases/get_active_payment_methods_usecase.dart';
import '../../domain/entities/payable_invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/get_payable_invoices_usecase.dart';
import '../../domain/usecases/get_payment_business_date_usecase.dart';
import '../../domain/usecases/payment_params.dart';
import '../../domain/usecases/register_payment_usecase.dart';
import 'register_payment_state.dart';

final class RegisterPaymentCubit extends Cubit<RegisterPaymentState> {
  final GetPayableInvoicesUseCase getPayableInvoicesUseCase;
  final GetActivePaymentMethodsUseCase getActivePaymentMethodsUseCase;
  final GetPaymentBusinessDateUseCase getPaymentBusinessDateUseCase;
  final RegisterPaymentUseCase registerPaymentUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  RegisterPaymentCubit({
    required this.getPayableInvoicesUseCase,
    required this.getActivePaymentMethodsUseCase,
    required this.getPaymentBusinessDateUseCase,
    required this.registerPaymentUseCase,
  }) : super(const RegisterPaymentInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    emit(const RegisterPaymentLoading());

    final invoicesResult = await getPayableInvoicesUseCase(
      GetPayableInvoicesParams(currentCompanyContext: currentCompanyContext),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;
    if (invoicesResult is FailureResult<List<PayableInvoice>>) {
      emit(RegisterPaymentFailure(invoicesResult.failure));
      return;
    }

    final methodsResult = await getActivePaymentMethodsUseCase(
      GetActivePaymentMethodsParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;
    if (methodsResult is FailureResult<List<PaymentMethod>>) {
      emit(RegisterPaymentFailure(methodsResult.failure));
      return;
    }

    final businessDateResult = await getPaymentBusinessDateUseCase(
      GetPaymentBusinessDateParams(
        currentCompanyContext: currentCompanyContext,
      ),
    );
    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;
    if (businessDateResult is FailureResult<DateTime>) {
      emit(RegisterPaymentFailure(businessDateResult.failure));
      return;
    }

    emit(
      RegisterPaymentReady(
        currentCompanyContext: currentCompanyContext,
        payableInvoices:
            (invoicesResult as Success<List<PayableInvoice>>).data,
        paymentMethods: (methodsResult as Success<List<PaymentMethod>>).data,
        businessDate: (businessDateResult as Success<DateTime>).data,
      ),
    );
  }

  Future<void> retryLoad() async {
    final context = _currentCompanyContext;
    if (context != null) await load(context);
  }

  Future<bool> submit({
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required String amountText,
    String? referenceNumber,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null ||
        currentState is! RegisterPaymentReady ||
        currentState.isSubmitting) {
      return false;
    }

    final companyId = context.companyId;
    emit(
      currentState.copyWith(
        isSubmitting: true,
        submissionFailure: null,
        completedPayment: null,
      ),
    );

    final result = await registerPaymentUseCase(
      RegisterPaymentParams(
        currentCompanyContext: context,
        invoiceId: invoiceId,
        paymentMethodId: paymentMethodId,
        paymentDate: paymentDate,
        amountText: amountText,
        referenceNumber: referenceNumber,
        notes: notes,
      ),
    );
    if (_currentCompanyContext?.companyId != companyId) return false;

    final latestState = state;
    if (latestState is! RegisterPaymentReady) return false;

    var succeeded = false;
    result.when(
      success: (payment) {
        succeeded = true;
        emit(
          latestState.copyWith(
            isSubmitting: false,
            submissionFailure: null,
            completedPayment: payment,
            feedbackSequence: latestState.feedbackSequence + 1,
          ),
        );
      },
      failure: (failure) {
        emit(
          latestState.copyWith(
            isSubmitting: false,
            submissionFailure: failure,
            completedPayment: null,
            feedbackSequence: latestState.feedbackSequence + 1,
          ),
        );
      },
    );
    return succeeded;
  }

  bool _isCurrentLoad(int requestId, String companyId) {
    return requestId == _loadRequestId &&
        _currentCompanyContext?.companyId == companyId;
  }
}
