import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_status_filter.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/add_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/deactivate_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/get_payment_methods_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/reactivate_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/update_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/presentation/cubit/payment_methods_cubit.dart';
import 'package:horus_system/features/payment_methods/presentation/cubit/payment_methods_state.dart';
import 'package:test/test.dart';

import '../../helpers/fake_payment_methods_repository.dart';

void main() {
  test('load and filter keep presentation state local to the cubit', () async {
    final repository = FakePaymentMethodsRepository()
      ..methods = const [
        PaymentMethod(
          id: 'cash',
          companyId: 'company-1',
          name: 'Cash',
          isActive: true,
        ),
        PaymentMethod(
          id: 'cheque',
          companyId: 'company-1',
          name: 'Cheque',
          isActive: false,
        ),
      ];
    final cubit = _cubit(repository);

    await cubit.loadPaymentMethods(_context());
    var loaded = cubit.state as PaymentMethodsLoaded;
    expect(loaded.visibleMethods.map((item) => item.id), ['cash']);
    expect(loaded.canManagePaymentMethods, isTrue);

    cubit.setStatusFilter(PaymentMethodStatusFilter.inactive);
    loaded = cubit.state as PaymentMethodsLoaded;
    expect(loaded.visibleMethods.map((item) => item.id), ['cheque']);

    await cubit.close();
  });

  test('successful add upserts locally and emits mutation feedback', () async {
    final repository = FakePaymentMethodsRepository();
    final cubit = _cubit(repository);
    await cubit.loadPaymentMethods(_context());

    final succeeded = await cubit.addPaymentMethod('Cash');
    final loaded = cubit.state as PaymentMethodsLoaded;

    expect(succeeded, isTrue);
    expect(loaded.allMethods.single.name, 'Cash');
    expect(loaded.completedMutation, PaymentMethodMutation.created);
    expect(loaded.feedbackSequence, 1);
    await cubit.close();
  });

  test('mutation failure preserves loaded data and exposes typed failure', () async {
    final repository = FakePaymentMethodsRepository()
      ..methods = const [
        PaymentMethod(
          id: 'cash',
          companyId: 'company-1',
          name: 'Cash',
          isActive: true,
        ),
      ];
    final cubit = _cubit(repository);
    await cubit.loadPaymentMethods(_context());
    repository.nextFailure = const ConflictFailure(
      code: FailureCodes.conflictPaymentMethodDuplicateName,
    );

    final succeeded = await cubit.addPaymentMethod('cash');
    final loaded = cubit.state as PaymentMethodsLoaded;

    expect(succeeded, isFalse);
    expect(loaded.allMethods.single.id, 'cash');
    expect(
      loaded.mutationFailure?.code,
      FailureCodes.conflictPaymentMethodDuplicateName,
    );
    expect(loaded.isSubmitting, isFalse);
    await cubit.close();
  });

  test('submit mutation blocks status mutation until it completes', () async {
    const cash = PaymentMethod(
      id: 'cash',
      companyId: 'company-1',
      name: 'Cash',
      isActive: true,
    );
    final completer = Completer<Result<PaymentMethod>>();
    final repository = FakePaymentMethodsRepository()
      ..methods = const [cash]
      ..mutationCompleter = completer;
    final cubit = _cubit(repository);
    await cubit.loadPaymentMethods(_context());

    final addFuture = cubit.addPaymentMethod('Card');
    final pending = cubit.state as PaymentMethodsLoaded;
    expect(pending.isSubmitting, isTrue);
    expect(pending.isMutationPending, isTrue);

    final statusSucceeded = await cubit.deactivatePaymentMethod(cash);
    expect(statusSucceeded, isFalse);

    completer.complete(
      const Success(
        PaymentMethod(
          id: 'card',
          companyId: 'company-1',
          name: 'Card',
          isActive: true,
        ),
      ),
    );
    expect(await addFuture, isTrue);
    expect((cubit.state as PaymentMethodsLoaded).isMutationPending, isFalse);
    await cubit.close();
  });

  test('status mutation blocks submit mutation until it completes', () async {
    const cash = PaymentMethod(
      id: 'cash',
      companyId: 'company-1',
      name: 'Cash',
      isActive: true,
    );
    final completer = Completer<Result<PaymentMethod>>();
    final repository = FakePaymentMethodsRepository()
      ..methods = const [cash]
      ..mutationCompleter = completer;
    final cubit = _cubit(repository);
    await cubit.loadPaymentMethods(_context());

    final deactivateFuture = cubit.deactivatePaymentMethod(cash);
    final pending = cubit.state as PaymentMethodsLoaded;
    expect(pending.pendingActionPaymentMethodId, 'cash');
    expect(pending.isMutationPending, isTrue);

    final addSucceeded = await cubit.addPaymentMethod('Card');
    expect(addSucceeded, isFalse);

    completer.complete(
      const Success(
        PaymentMethod(
          id: 'cash',
          companyId: 'company-1',
          name: 'Cash',
          isActive: false,
        ),
      ),
    );
    expect(await deactivateFuture, isTrue);
    expect((cubit.state as PaymentMethodsLoaded).isMutationPending, isFalse);
    await cubit.close();
  });
}

PaymentMethodsCubit _cubit(FakePaymentMethodsRepository repository) {
  return PaymentMethodsCubit(
    getPaymentMethodsUseCase: GetPaymentMethodsUseCase(repository),
    addPaymentMethodUseCase: AddPaymentMethodUseCase(repository),
    updatePaymentMethodUseCase: UpdatePaymentMethodUseCase(repository),
    deactivatePaymentMethodUseCase: DeactivatePaymentMethodUseCase(repository),
    reactivatePaymentMethodUseCase: ReactivatePaymentMethodUseCase(repository),
  );
}

CurrentCompanyContext _context() {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: CompanyRole.accountant,
  );
}
