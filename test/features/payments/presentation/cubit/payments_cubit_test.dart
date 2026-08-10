import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_creation_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoices_repository.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_query_usecases.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:horus_system/features/payment_methods/domain/repositories/payment_methods_repository.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/get_payment_methods_usecase.dart';
import 'package:horus_system/features/payments/domain/entities/payment.dart';
import 'package:horus_system/features/payments/domain/repositories/payments_repository.dart';
import 'package:horus_system/features/payments/domain/usecases/payment_usecases.dart';
import 'package:horus_system/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:horus_system/features/payments/presentation/cubit/payments_state.dart';
import 'package:test/test.dart';

void main() {
  test('accountant load exposes registration capability', () async {
    final payments = _FakePaymentsRepository();
    final invoices = _FakeInvoicesRepository();
    final methods = _FakePaymentMethodsRepository();
    final cubit = _cubit(payments, invoices, methods);

    await cubit.loadPayments(_context(CompanyRole.accountant));

    final state = cubit.state as PaymentsLoaded;
    expect(state.canRegisterPayments, isTrue);
    expect(payments.lastCompanyId, 'company-1');
    expect(invoices.lastCompanyId, 'company-1');
    expect(methods.lastCompanyId, 'company-1');
    await cubit.close();
  });

  test('operations load remains read-only in presentation state', () async {
    final cubit = _cubit(
      _FakePaymentsRepository(),
      _FakeInvoicesRepository(),
      _FakePaymentMethodsRepository(),
    );

    await cubit.loadPayments(_context(CompanyRole.operations));

    final state = cubit.state as PaymentsLoaded;
    expect(state.canRegisterPayments, isFalse);
    await cubit.close();
  });

  test('search query stays presentation-only', () async {
    final cubit = _cubit(
      _FakePaymentsRepository(),
      _FakeInvoicesRepository(),
      _FakePaymentMethodsRepository(),
    );
    await cubit.loadPayments(_context(CompanyRole.accountant));

    cubit.setSearchQuery('reference');

    final state = cubit.state as PaymentsLoaded;
    expect(state.searchQuery, 'reference');
    await cubit.close();
  });
}

PaymentsCubit _cubit(
  _FakePaymentsRepository payments,
  _FakeInvoicesRepository invoices,
  _FakePaymentMethodsRepository methods,
) {
  return PaymentsCubit(
    getPaymentsUseCase: GetPaymentsUseCase(payments),
    getInvoicesUseCase: GetInvoicesUseCase(invoices),
    getPaymentMethodsUseCase: GetPaymentMethodsUseCase(methods),
  );
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}

final class _FakePaymentsRepository implements PaymentsRepository {
  String? lastCompanyId;

  @override
  Future<Result<List<Payment>>> getPayments({required String companyId}) async {
    lastCompanyId = companyId;
    return const Success<List<Payment>>([]);
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) => throw UnimplementedError();

  @override
  Future<Result<Payment>> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required dynamic amount,
    String? referenceNumber,
    String? notes,
  }) => throw UnimplementedError();
}

final class _FakeInvoicesRepository implements InvoicesRepository {
  String? lastCompanyId;

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) async {
    lastCompanyId = companyId;
    return const Success<List<Invoice>>([]);
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) => throw UnimplementedError();

  @override
  Future<Result<List<BillableTrip>>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) => throw UnimplementedError();

  @override
  Future<Result<InvoiceCreationContext>> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) => throw UnimplementedError();

  @override
  Future<Result<Invoice>> createInvoiceDraft({
    required InvoiceDraftData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Invoice>> updateInvoiceDraft({
    required String invoiceId,
    required InvoiceDraftData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Invoice>> issueInvoice({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<Invoice>> cancelInvoice({
    required String companyId,
    required String invoiceId,
    required String reason,
    required String actorRole,
  }) => throw UnimplementedError();
}

final class _FakePaymentMethodsRepository implements PaymentMethodsRepository {
  String? lastCompanyId;

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    return const Success<List<PaymentMethod>>([]);
  }

  @override
  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  }) => throw UnimplementedError();

  @override
  Future<Result<PaymentMethod>> addPaymentMethod({
    required PaymentMethodWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<PaymentMethod>> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<PaymentMethod>> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) => throw UnimplementedError();

  @override
  Future<Result<PaymentMethod>> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  }) => throw UnimplementedError();
}
