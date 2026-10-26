part of 'payments_cubit.dart';

/// Reconciles payment history from the server without disturbing the user's
/// search or the separate invoice-reference refresh owned by R4.5.
mixin PaymentsRealtimeActions on Cubit<PaymentsState> {
  Future<void> refreshPaymentsFromRealtime() async {
    final owner = this as PaymentsCubit;
    if (isClosed) return;

    owner._paymentsRefreshPending = true;
    if (owner._paymentsRefreshInProgress) return;
    owner._paymentsRefreshInProgress = true;
    try {
      while (owner._paymentsRefreshPending && !isClosed) {
        owner._paymentsRefreshPending = false;
        final current = state;
        final companyContext = owner._currentCompanyContext;
        if (current is! PaymentsLoaded || companyContext == null) {
          // An initial load may still be pending. It drains this flag.
          owner._paymentsRefreshPending = true;
          break;
        }

        final requestId = owner._loadRequestId;
        final result = await owner.getPaymentsUseCase(
          GetPaymentsParams(currentCompanyContext: companyContext),
        );
        if (!owner._isCurrentLoad(requestId, companyContext.companyId)) {
          return;
        }
        final paymentFailure = result.failureOrNull;
        if (paymentFailure != null) {
          _reportPaymentRefreshFailure(paymentFailure);
          continue;
        }

        final payments = result.dataOrNull ?? const <Payment>[];
        final timestampsResult = await owner
            .convertInstantsToBusinessLocalDateTimesUseCase(
              ConvertInstantsToBusinessLocalDateTimesParams(
                timeZoneId: companyContext.company.businessTimezone ?? '',
                instantsByKey: {
                  for (final payment in payments) payment.id: payment.createdAt,
                },
              ),
            );
        if (!owner._isCurrentLoad(requestId, companyContext.companyId)) {
          return;
        }
        final timestampFailure = timestampsResult.failureOrNull;
        if (timestampFailure != null) {
          _reportPaymentRefreshFailure(timestampFailure);
          continue;
        }

        final latest = state;
        if (latest is! PaymentsLoaded) {
          owner._paymentsRefreshPending = true;
          break;
        }
        if (owner._paymentsRefreshPending) {
          // A newer event arrived while reading; discard the stale snapshot.
          continue;
        }

        emit(
          latest.copyWith(
            allPayments: List.unmodifiable(payments),
            createdAtByPaymentId: Map.unmodifiable(
              timestampsResult.dataOrNull ??
                  const <String, BusinessLocalDateTime>{},
            ),
            paymentsRefreshFailure: null,
          ),
        );
      }
    } finally {
      owner._paymentsRefreshInProgress = false;
    }
  }

  void _reportPaymentRefreshFailure(Failure failure) {
    final latest = state;
    if (latest is! PaymentsLoaded) return;
    if (failure is AuthFailure || failure is PermissionFailure) {
      emit(PaymentsFailure(failure));
    } else {
      // Keep the most recent successful list and the user's active search.
      emit(latest.copyWith(paymentsRefreshFailure: failure));
    }
  }
}
