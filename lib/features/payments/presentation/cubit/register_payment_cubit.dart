import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/common_failures.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/usecases/get_active_payment_methods_usecase.dart';
import '../../domain/entities/payable_invoice.dart';
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
  bool _invoiceRefreshPending = false;
  bool _invoiceRefreshInProgress = false;

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
    if (businessDateResult is FailureResult<BusinessDate>) {
      emit(RegisterPaymentFailure(businessDateResult.failure));
      return;
    }

    emit(
      RegisterPaymentReady(
        currentCompanyContext: currentCompanyContext,
        payableInvoices: (invoicesResult as Success<List<PayableInvoice>>).data,
        paymentMethods: (methodsResult as Success<List<PaymentMethod>>).data,
        businessDate: (businessDateResult as Success<BusinessDate>).data,
      ),
    );
    _drainPendingInvoiceRefresh();
  }

  /// Re-read server-authoritative payment options while retaining the form.
  /// Pending payment submissions finish before their invalidations are applied.
  Future<void> refreshPayableInvoicesFromRealtime() async {
    _invoiceRefreshPending = true;
    if (_invoiceRefreshInProgress) return;
    _invoiceRefreshInProgress = true;
    try {
      while (_invoiceRefreshPending && !isClosed) {
        _invoiceRefreshPending = false;
        final current = state;
        final context = _currentCompanyContext;
        if (current is! RegisterPaymentReady ||
            context == null ||
            current.isSubmitting) {
          _invoiceRefreshPending = true;
          break;
        }

        final requestId = _loadRequestId;
        final result = await getPayableInvoicesUseCase(
          GetPayableInvoicesParams(currentCompanyContext: context),
        );
        if (!_isCurrentLoad(requestId, context.companyId)) return;

        final latest = state;
        if (latest is! RegisterPaymentReady || latest.isSubmitting) {
          _invoiceRefreshPending = true;
          break;
        }

        final failure = result.failureOrNull;
        if (failure is AuthFailure || failure is PermissionFailure) {
          emit(RegisterPaymentFailure(failure));
          break;
        }
        emit(
          latest.copyWith(
            payableInvoices: failure == null ? result.dataOrNull! : null,
            invoiceRefreshFailure: failure,
          ),
        );
      }
    } finally {
      _invoiceRefreshInProgress = false;
    }
  }

  void _drainPendingInvoiceRefresh() {
    if (_invoiceRefreshPending && !isClosed) {
      unawaited(refreshPayableInvoicesFromRealtime());
    }
  }

  Future<void> retryLoad() async {
    final context = _currentCompanyContext;
    if (context != null) await load(context);
  }

  Future<bool> submit({
    required String invoiceId,
    required String paymentMethodId,
    required BusinessDate paymentDate,
    required String amountText,
    String? referenceNumber,
    String? notes,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null ||
        currentState is! RegisterPaymentReady ||
        currentState.isSubmitting ||
        !currentState.payableInvoices.any(
          (item) => item.invoice.id == invoiceId,
        )) {
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
    if (isClosed || _currentCompanyContext?.companyId != companyId) {
      return false;
    }

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
    _drainPendingInvoiceRefresh();
    return succeeded;
  }

  bool _isCurrentLoad(int requestId, String companyId) {
    return !isClosed &&
        requestId == _loadRequestId &&
        _currentCompanyContext?.companyId == companyId;
  }
}
