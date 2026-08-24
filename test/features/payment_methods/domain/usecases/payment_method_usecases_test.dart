import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/add_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/deactivate_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/get_active_payment_methods_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/get_payment_methods_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/reactivate_payment_method_usecase.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/update_payment_method_usecase.dart';
import 'package:test/test.dart';

import '../../helpers/fake_payment_methods_repository.dart';

void main() {
  group('payment method use cases', () {
    test('add validates required name before repository call', () async {
      final repository = FakePaymentMethodsRepository();
      final result = await AddPaymentMethodUseCase(repository)(
        AddPaymentMethodParams(
          currentCompanyContext: _context(CompanyRole.owner),
          name: '   ',
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationPaymentMethodNameRequired,
      );
      expect(repository.lastWriteData, isNull);
    });

    test('add trims name and forwards company and actor role', () async {
      final repository = FakePaymentMethodsRepository();
      final result = await AddPaymentMethodUseCase(repository)(
        AddPaymentMethodParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          name: '  Bank Transfer  ',
        ),
      );

      expect(result.dataOrNull?.name, 'Bank Transfer');
      expect(repository.lastWriteData?.companyId, 'company-1');
      expect(repository.lastWriteData?.name, 'Bank Transfer');
      expect(repository.lastActorRole, 'accountant');
    });

    test('unauthorized role cannot add payment methods', () async {
      final repository = FakePaymentMethodsRepository();
      final result = await AddPaymentMethodUseCase(repository)(
        AddPaymentMethodParams(
          currentCompanyContext: _context(CompanyRole.viewer),
          name: 'Cash',
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionPaymentMethodsManagement,
      );
      expect(repository.lastWriteData, isNull);
    });

    test('update validates id and trims the edited name', () async {
      final repository = FakePaymentMethodsRepository();
      final useCase = UpdatePaymentMethodUseCase(repository);

      final invalidResult = await useCase(
        UpdatePaymentMethodParams(
          currentCompanyContext: _context(CompanyRole.owner),
          paymentMethodId: '   ',
          name: 'Cash',
        ),
      );
      expect(
        invalidResult.failureOrNull?.code,
        FailureCodes.validationPaymentMethodIdRequired,
      );

      final result = await useCase(
        UpdatePaymentMethodParams(
          currentCompanyContext: _context(CompanyRole.admin),
          paymentMethodId: 'method-1',
          name: '  Card  ',
        ),
      );
      expect(result.dataOrNull?.name, 'Card');
      expect(repository.lastPaymentMethodId, 'method-1');
      expect(repository.lastWriteData?.name, 'Card');
      expect(repository.lastActorRole, 'admin');
    });

    test('deactivate and reactivate keep company and role scoped', () async {
      final repository = FakePaymentMethodsRepository()
        ..methods = const [
          PaymentMethod(
            id: 'method-1',
            companyId: 'company-1',
            name: 'Cash',
            isActive: true,
          ),
        ];
      final context = _context(CompanyRole.accountant);

      final deactivated = await DeactivatePaymentMethodUseCase(repository)(
        DeactivatePaymentMethodParams(
          currentCompanyContext: context,
          paymentMethodId: 'method-1',
        ),
      );
      expect(deactivated.dataOrNull?.isActive, isFalse);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastActorRole, 'accountant');

      final reactivated = await ReactivatePaymentMethodUseCase(repository)(
        ReactivatePaymentMethodParams(
          currentCompanyContext: context,
          paymentMethodId: 'method-1',
        ),
      );
      expect(reactivated.dataOrNull?.isActive, isTrue);
    });

    test('all-methods read denies permission before company validation', () async {
      final repository = FakePaymentMethodsRepository();

      final result = await GetPaymentMethodsUseCase(repository)(
        GetPaymentMethodsParams(
          currentCompanyContext: _context(
            CompanyRole.driver,
            companyId: '   ',
          ),
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionPaymentMethodsView,
      );
      expect(repository.getAllCalls, 0);
    });

    test('all-methods read rejects blank company id before repository', () async {
      final repository = FakePaymentMethodsRepository();

      final result = await GetPaymentMethodsUseCase(repository)(
        GetPaymentMethodsParams(
          currentCompanyContext: _context(
            CompanyRole.owner,
            companyId: '   ',
          ),
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyIdRequired,
      );
      expect(repository.getAllCalls, 0);
    });

    test('all-methods read trims company id before repository call', () async {
      final repository = FakePaymentMethodsRepository()
        ..methods = const [
          PaymentMethod(
            id: 'cash',
            companyId: 'company-1',
            name: 'Cash',
            isActive: true,
          ),
        ];

      final result = await GetPaymentMethodsUseCase(repository)(
        GetPaymentMethodsParams(
          currentCompanyContext: _context(
            CompanyRole.admin,
            companyId: '  company-1  ',
          ),
        ),
      );

      expect(result.dataOrNull?.single.id, 'cash');
      expect(repository.getAllCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
    });

    test('active-methods read denies permission before company validation', () async {
      final repository = FakePaymentMethodsRepository();

      final result = await GetActivePaymentMethodsUseCase(repository)(
        GetActivePaymentMethodsParams(
          currentCompanyContext: _context(
            CompanyRole.driver,
            companyId: '   ',
          ),
        ),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionPaymentMethodsView,
      );
      expect(repository.getActiveCalls, 0);
    });

    test('active-methods read validates and trims company id', () async {
      final repository = FakePaymentMethodsRepository()
        ..activeMethods = const [
          PaymentMethod(
            id: 'cash',
            companyId: 'company-1',
            name: 'Cash',
            isActive: true,
          ),
        ];
      final useCase = GetActivePaymentMethodsUseCase(repository);

      final invalidResult = await useCase(
        GetActivePaymentMethodsParams(
          currentCompanyContext: _context(
            CompanyRole.accountant,
            companyId: '   ',
          ),
        ),
      );
      expect(
        invalidResult.failureOrNull?.code,
        FailureCodes.validationCompanyIdRequired,
      );
      expect(repository.getActiveCalls, 0);

      final result = await useCase(
        GetActivePaymentMethodsParams(
          currentCompanyContext: _context(
            CompanyRole.accountant,
            companyId: '  company-1  ',
          ),
        ),
      );

      expect(result.dataOrNull?.single.id, 'cash');
      expect(repository.getActiveCalls, 1);
      expect(repository.getAllCalls, 0);
      expect(repository.lastCompanyId, 'company-1');
    });
  });
}

CurrentCompanyContext _context(
  CompanyRole role, {
  String companyId = 'company-1',
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Company One'),
    role: role,
  );
}
