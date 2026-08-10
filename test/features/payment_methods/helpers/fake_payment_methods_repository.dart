import 'dart:async';

import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:horus_system/features/payment_methods/domain/repositories/payment_methods_repository.dart';

final class FakePaymentMethodsRepository implements PaymentMethodsRepository {
  List<PaymentMethod> methods = const [];
  List<PaymentMethod> activeMethods = const [];
  Failure? nextFailure;
  Completer<Result<PaymentMethod>>? mutationCompleter;
  PaymentMethodWriteData? lastWriteData;
  String? lastActorRole;
  String? lastPaymentMethodId;
  String? lastCompanyId;
  int getAllCalls = 0;
  int getActiveCalls = 0;

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) async {
    getAllCalls += 1;
    lastCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(methods);
  }

  @override
  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  }) async {
    getActiveCalls += 1;
    lastCompanyId = companyId;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);
    return Success(activeMethods);
  }

  @override
  Future<Result<PaymentMethod>> addPaymentMethod({
    required PaymentMethodWriteData data,
    required String actorRole,
  }) async {
    lastWriteData = data;
    lastActorRole = actorRole;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);

    final pendingMutation = mutationCompleter;
    if (pendingMutation != null) return pendingMutation.future;

    return Success(
      PaymentMethod(
        id: 'method-new',
        companyId: data.companyId,
        name: data.name,
        isActive: true,
      ),
    );
  }

  @override
  Future<Result<PaymentMethod>> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
    required String actorRole,
  }) async {
    lastPaymentMethodId = paymentMethodId;
    lastWriteData = data;
    lastActorRole = actorRole;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);

    final pendingMutation = mutationCompleter;
    if (pendingMutation != null) return pendingMutation.future;

    return Success(
      PaymentMethod(
        id: paymentMethodId,
        companyId: data.companyId,
        name: data.name,
        isActive: true,
      ),
    );
  }

  @override
  Future<Result<PaymentMethod>> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      paymentMethodId: paymentMethodId,
      actorRole: actorRole,
      isActive: false,
    );
  }

  @override
  Future<Result<PaymentMethod>> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) {
    return _changeStatus(
      companyId: companyId,
      paymentMethodId: paymentMethodId,
      actorRole: actorRole,
      isActive: true,
    );
  }

  Future<Result<PaymentMethod>> _changeStatus({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
    required bool isActive,
  }) async {
    lastCompanyId = companyId;
    lastPaymentMethodId = paymentMethodId;
    lastActorRole = actorRole;
    final failure = nextFailure;
    if (failure != null) return FailureResult(failure);

    final pendingMutation = mutationCompleter;
    if (pendingMutation != null) return pendingMutation.future;

    String name = 'Method';
    for (final method in methods) {
      if (method.id == paymentMethodId) {
        name = method.name;
        break;
      }
    }
    return Success(
      PaymentMethod(
        id: paymentMethodId,
        companyId: companyId,
        name: name,
        isActive: isActive,
      ),
    );
  }
}
