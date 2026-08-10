import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_creation_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoices_repository.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:horus_system/features/payment_methods/domain/repositories/payment_methods_repository.dart';
import 'package:horus_system/features/payment_methods/domain/usecases/get_active_payment_methods_usecase.dart';
import 'package:horus_system/features/payments/domain/entities/payment.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:horus_system/features/payments/domain/repositories/payments_repository.dart';
import 'package:horus_system/features/payments/domain/usecases/payment_usecases.dart';
import 'package:horus_system/features/payments/presentation/cubit/register_payment_cubit.dart';
import 'package:horus_system/features/payments/presentation/cubit/register_payment_state.dart';
import 'package:test/test.dart';

void main() {
  test('load prepares payable invoices methods and business date', () async {
    final fixture = _Fixture();

    await fixture.cubit.load(fixture.context);

    final state = fixture.cubit.state as RegisterPaymentReady;
    expect(state.payableInvoices.single.invoice.id, 'invoice-1');
    expect(state.paymentMethods.single.id, 'method-1');
    expect(state.businessDate, DateTime.utc(2026, 8, 10));
    await fixture.cubit.close();
  });

  test('successful submit exposes completion and exact amount', () async {
    final fixture = _Fixture();
    await fixture.cubit.load(fixture.context);

    final succeeded = await fixture.cubit.submit(
      invoiceId: 'invoice-1',
      paymentMethodId: 'method-1',
      paymentDate: DateTime.utc(2026, 8, 10),
      amountText: '400.00',
      referenceNumber: 'REF-1',
    );

    final state = fixture.cubit.state as RegisterPaymentReady;
    expect(succeeded, isTrue);
    expect(state.completedPayment?.amount.minorUnits, 40000);
    expect(state.submissionFailure, isNull);
    expect(state.feedbackSequence, 1);
    expect(fixture.payments.registerCalls, 1);
    await fixture.cubit.close();
  });

  test('domain failure remains typed in ready state', () async {
    final fixture = _Fixture();
    await fixture.cubit.load(fixture.context);

    final succeeded = await fixture.cubit.submit(
      invoiceId: 'invoice-1',
      paymentMethodId: 'method-1',
      paymentDate: DateTime.utc(2026, 8, 10),
      amountText: '1200.01',
    );

    final state = fixture.cubit.state as RegisterPaymentReady;
    expect(succeeded, isFalse);
    expect(
      state.submissionFailure?.code,
      PaymentFailureCodes.conflictOverpayment,
    );
    expect(state.completedPayment, isNull);
    expect(state.isSubmitting, isFalse);
    expect(fixture.payments.registerCalls, 0);
    await fixture.cubit.close();
  });
}

final class _Fixture {
  final context = CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: CompanyRole.accountant,
  );

  late final _FakePaymentsRepository payments;
  late final _FakeInvoicesRepository invoices;
  late final _FakePaymentMethodsRepository methods;
  late final RegisterPaymentCubit cubit;

  _Fixture() {
    payments = _FakePaymentsRepository();
    invoices = _FakeInvoicesRepository(_invoice());
    methods = _FakePaymentMethodsRepository();
    final businessDate = _FixedBusinessDateProvider(DateTime.utc(2026, 8, 10));

    cubit = RegisterPaymentCubit(
      getPayableInvoicesUseCase: GetPayableInvoicesUseCase(
        invoicesRepository: invoices,
        paymentsRepository: payments,
      ),
      getActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase(methods),
      getPaymentBusinessDateUseCase: GetPaymentBusinessDateUseCase(
        businessDate,
      ),
      registerPaymentUseCase: RegisterPaymentUseCase(
        paymentsRepository: payments,
        invoicesRepository: invoices,
        paymentMethodsRepository: methods,
        businessDateProvider: businessDate,
      ),
    );
  }
}

Invoice _invoice() {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final total = Money(minorUnits: 120000, currency: currency);
  return Invoice(
    id: 'invoice-1',
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer',
    ),
    status: InvoiceStatus.issued,
    currency: currency,
    lines: [InvoiceTripLine(tripId: 'trip-1', amount: total)],
    totals: InvoiceTotals(
      subtotal: total,
      discount: zero,
      taxableAmount: total,
      taxRate: TaxRate.tryCreate(0)!,
      taxAmount: zero,
      grandTotal: total,
    ),
    issueDate: InvoiceDate.fromDateTime(DateTime.utc(2026, 8, 10)),
    dueDate: InvoiceDate.fromDateTime(DateTime.utc(2026, 8, 31)),
    createdAt: DateTime.utc(2026, 8, 10),
    updatedAt: DateTime.utc(2026, 8, 10),
  );
}

final class _FixedBusinessDateProvider implements CompanyBusinessDateProvider {
  final DateTime date;

  const _FixedBusinessDateProvider(this.date);

  @override
  Future<Result<DateTime>> getBusinessDate({required String companyId}) async {
    return Success<DateTime>(date);
  }
}

final class _FakePaymentsRepository implements PaymentsRepository {
  int registerCalls = 0;

  @override
  Future<Result<List<Payment>>> getPayments({required String companyId}) async {
    return const Success<List<Payment>>([]);
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) async {
    return const Success<List<Payment>>([]);
  }

  @override
  Future<Result<Payment>> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  }) async {
    registerCalls++;
    return Success<Payment>(
      Payment(
        id: 'payment-1',
        companyId: companyId,
        invoiceId: invoiceId,
        customerId: 'customer-1',
        paymentMethodId: paymentMethodId,
        paymentDate: paymentDate,
        amount: amount,
        referenceNumber: referenceNumber,
        notes: notes,
        createdAt: DateTime.utc(2026, 8, 10),
      ),
    );
  }
}

final class _FakeInvoicesRepository implements InvoicesRepository {
  final Invoice invoice;

  const _FakeInvoicesRepository(this.invoice);

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) async {
    return Success<List<Invoice>>([invoice]);
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    return Success<Invoice>(invoice);
  }

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
  static const method = PaymentMethod(
    id: 'method-1',
    companyId: 'company-1',
    name: 'Cash',
    isActive: true,
  );

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) async {
    return const Success<List<PaymentMethod>>([method]);
  }

  @override
  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  }) async {
    return const Success<List<PaymentMethod>>([method]);
  }

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
