import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_status_filter.dart';
import '../../domain/policies/payment_methods_permission_policy.dart';
import '../../domain/usecases/add_payment_method_usecase.dart';
import '../../domain/usecases/deactivate_payment_method_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/reactivate_payment_method_usecase.dart';
import '../../domain/usecases/update_payment_method_usecase.dart';
import 'payment_methods_state.dart';

class PaymentMethodsCubit extends Cubit<PaymentMethodsState> {
  final GetPaymentMethodsUseCase getPaymentMethodsUseCase;
  final AddPaymentMethodUseCase addPaymentMethodUseCase;
  final UpdatePaymentMethodUseCase updatePaymentMethodUseCase;
  final DeactivatePaymentMethodUseCase deactivatePaymentMethodUseCase;
  final ReactivatePaymentMethodUseCase reactivatePaymentMethodUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _loadRequestId = 0;

  PaymentMethodsCubit({
    required this.getPaymentMethodsUseCase,
    required this.addPaymentMethodUseCase,
    required this.updatePaymentMethodUseCase,
    required this.deactivatePaymentMethodUseCase,
    required this.reactivatePaymentMethodUseCase,
  }) : super(const PaymentMethodsInitial());

  Future<void> loadPaymentMethods(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_loadRequestId;
    final previousState = state;
    final previousFilter = previousState is PaymentMethodsLoaded
        ? previousState.statusFilter
        : PaymentMethodStatusFilter.active;

    emit(const PaymentMethodsLoading());
    final result = await getPaymentMethodsUseCase(
      GetPaymentMethodsParams(currentCompanyContext: currentCompanyContext),
    );

    if (!_isCurrentLoad(requestId, currentCompanyContext.companyId)) return;

    result.when(
      success: (methods) => emit(
        PaymentMethodsLoaded(
          currentCompanyContext: currentCompanyContext,
          allMethods: _sortMethods(methods),
          statusFilter: previousFilter,
          canManagePaymentMethods:
              PaymentMethodsPermissionPolicy.canManagePaymentMethods(
                currentCompanyContext.role,
              ),
        ),
      ),
      failure: (failure) => emit(PaymentMethodsFailure(failure)),
    );
  }

  void setStatusFilter(PaymentMethodStatusFilter filter) {
    final currentState = state;
    if (currentState is PaymentMethodsLoaded) {
      emit(currentState.copyWith(statusFilter: filter));
    }
  }

  Future<bool> addPaymentMethod(String name) {
    return _submitMutation(
      execute: (context) => addPaymentMethodUseCase(
        AddPaymentMethodParams(
          currentCompanyContext: context,
          name: name,
        ),
      ),
      mutation: PaymentMethodMutation.created,
    );
  }

  Future<bool> updatePaymentMethod({
    required PaymentMethod paymentMethod,
    required String name,
  }) {
    return _submitMutation(
      execute: (context) => updatePaymentMethodUseCase(
        UpdatePaymentMethodParams(
          currentCompanyContext: context,
          paymentMethodId: paymentMethod.id,
          name: name,
        ),
      ),
      mutation: PaymentMethodMutation.updated,
    );
  }

  Future<bool> deactivatePaymentMethod(PaymentMethod paymentMethod) {
    return _statusMutation(
      paymentMethod: paymentMethod,
      execute: (context) => deactivatePaymentMethodUseCase(
        DeactivatePaymentMethodParams(
          currentCompanyContext: context,
          paymentMethodId: paymentMethod.id,
        ),
      ),
      mutation: PaymentMethodMutation.deactivated,
    );
  }

  Future<bool> reactivatePaymentMethod(PaymentMethod paymentMethod) {
    return _statusMutation(
      paymentMethod: paymentMethod,
      execute: (context) => reactivatePaymentMethodUseCase(
        ReactivatePaymentMethodParams(
          currentCompanyContext: context,
          paymentMethodId: paymentMethod.id,
        ),
      ),
      mutation: PaymentMethodMutation.reactivated,
    );
  }

  Future<bool> _submitMutation({
    required Future<Result<PaymentMethod>> Function(
      CurrentCompanyContext context,
    )
    execute,
    required PaymentMethodMutation mutation,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null ||
        currentState is! PaymentMethodsLoaded ||
        currentState.isMutationPending) {
      return false;
    }

    final companyId = context.companyId;
    emit(
      currentState.copyWith(
        isSubmitting: true,
        mutationFailure: null,
        completedMutation: null,
      ),
    );

    final result = await execute(context);
    if (!_isCurrentCompany(companyId)) return false;

    final latestState = state;
    if (latestState is! PaymentMethodsLoaded) return false;

    var succeeded = false;
    result.when(
      success: (method) {
        succeeded = true;
        _emitMutationSuccess(
          state: latestState,
          method: method,
          mutation: mutation,
        );
      },
      failure: (failure) {
        _emitMutationFailure(
          state: latestState,
          failure: failure,
          clearSubmitting: true,
        );
      },
    );
    return succeeded;
  }

  Future<bool> _statusMutation({
    required PaymentMethod paymentMethod,
    required Future<Result<PaymentMethod>> Function(
      CurrentCompanyContext context,
    )
    execute,
    required PaymentMethodMutation mutation,
  }) async {
    final context = _currentCompanyContext;
    final currentState = state;
    if (context == null ||
        currentState is! PaymentMethodsLoaded ||
        currentState.isMutationPending) {
      return false;
    }

    final companyId = context.companyId;
    emit(
      currentState.copyWith(
        pendingActionPaymentMethodId: paymentMethod.id,
        mutationFailure: null,
        completedMutation: null,
      ),
    );

    final result = await execute(context);
    if (!_isCurrentCompany(companyId)) return false;

    final latestState = state;
    if (latestState is! PaymentMethodsLoaded) return false;

    var succeeded = false;
    result.when(
      success: (method) {
        succeeded = true;
        _emitMutationSuccess(
          state: latestState,
          method: method,
          mutation: mutation,
        );
      },
      failure: (failure) {
        _emitMutationFailure(
          state: latestState,
          failure: failure,
          clearPendingAction: true,
        );
      },
    );
    return succeeded;
  }

  void _emitMutationSuccess({
    required PaymentMethodsLoaded state,
    required PaymentMethod method,
    required PaymentMethodMutation mutation,
  }) {
    final updated = [...state.allMethods];
    final index = updated.indexWhere((item) => item.id == method.id);
    if (index == -1) {
      updated.add(method);
    } else {
      updated[index] = method;
    }

    emit(
      state.copyWith(
        allMethods: _sortMethods(updated),
        pendingActionPaymentMethodId: null,
        isSubmitting: false,
        mutationFailure: null,
        completedMutation: mutation,
        feedbackSequence: state.feedbackSequence + 1,
      ),
    );
  }

  void _emitMutationFailure({
    required PaymentMethodsLoaded state,
    required Failure failure,
    bool clearSubmitting = false,
    bool clearPendingAction = false,
  }) {
    emit(
      state.copyWith(
        pendingActionPaymentMethodId: clearPendingAction
            ? null
            : state.pendingActionPaymentMethodId,
        isSubmitting: clearSubmitting ? false : state.isSubmitting,
        mutationFailure: failure,
        completedMutation: null,
        feedbackSequence: state.feedbackSequence + 1,
      ),
    );
  }

  bool _isCurrentLoad(int requestId, String companyId) {
    return requestId == _loadRequestId && _isCurrentCompany(companyId);
  }

  bool _isCurrentCompany(String companyId) {
    return _currentCompanyContext?.companyId == companyId;
  }

  List<PaymentMethod> _sortMethods(Iterable<PaymentMethod> methods) {
    final sorted = methods.toList();
    sorted.sort(
      (left, right) => left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return sorted;
  }
}
