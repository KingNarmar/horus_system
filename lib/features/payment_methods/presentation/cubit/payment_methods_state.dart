import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_status_filter.dart';

enum PaymentMethodMutation { created, updated, deactivated, reactivated }

sealed class PaymentMethodsState {
  const PaymentMethodsState();
}

final class PaymentMethodsInitial extends PaymentMethodsState {
  const PaymentMethodsInitial();
}

final class PaymentMethodsLoading extends PaymentMethodsState {
  const PaymentMethodsLoading();
}

final class PaymentMethodsFailure extends PaymentMethodsState {
  final Failure failure;

  const PaymentMethodsFailure(this.failure);
}

final class PaymentMethodsLoaded extends PaymentMethodsState {
  static const Object _unset = Object();

  final CurrentCompanyContext currentCompanyContext;
  final List<PaymentMethod> allMethods;
  final PaymentMethodStatusFilter statusFilter;
  final bool canManagePaymentMethods;
  final String? pendingActionPaymentMethodId;
  final bool isSubmitting;
  final Failure? mutationFailure;
  final PaymentMethodMutation? completedMutation;
  final int feedbackSequence;

  const PaymentMethodsLoaded({
    required this.currentCompanyContext,
    required this.allMethods,
    required this.canManagePaymentMethods,
    this.statusFilter = PaymentMethodStatusFilter.active,
    this.pendingActionPaymentMethodId,
    this.isSubmitting = false,
    this.mutationFailure,
    this.completedMutation,
    this.feedbackSequence = 0,
  });

  List<PaymentMethod> get visibleMethods => allMethods
      .where(statusFilter.matches)
      .toList(growable: false);

  PaymentMethodsLoaded copyWith({
    List<PaymentMethod>? allMethods,
    PaymentMethodStatusFilter? statusFilter,
    bool? canManagePaymentMethods,
    Object? pendingActionPaymentMethodId = _unset,
    bool? isSubmitting,
    Object? mutationFailure = _unset,
    Object? completedMutation = _unset,
    int? feedbackSequence,
  }) {
    return PaymentMethodsLoaded(
      currentCompanyContext: currentCompanyContext,
      allMethods: allMethods ?? this.allMethods,
      statusFilter: statusFilter ?? this.statusFilter,
      canManagePaymentMethods:
          canManagePaymentMethods ?? this.canManagePaymentMethods,
      pendingActionPaymentMethodId:
          identical(pendingActionPaymentMethodId, _unset)
          ? this.pendingActionPaymentMethodId
          : pendingActionPaymentMethodId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      mutationFailure: identical(mutationFailure, _unset)
          ? this.mutationFailure
          : mutationFailure as Failure?,
      completedMutation: identical(completedMutation, _unset)
          ? this.completedMutation
          : completedMutation as PaymentMethodMutation?,
      feedbackSequence: feedbackSequence ?? this.feedbackSequence,
    );
  }
}
