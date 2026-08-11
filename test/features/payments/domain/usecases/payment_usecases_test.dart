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
import 'package:horus_system/features/payments/domain/entities/payment.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:horus_system/features/payments/domain/repositories/payments_repository.dart';
import 'package:horus_system/features/payments/domain/usecases/payment_params.dart';
import 'package:horus_system/features/payments/domain/usecases/payment_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('RegisterPaymentUseCase', () {
    test('operations cannot register payments', () async {
      final fixture = _Fixture(role: CompanyRole.operations);

      final result = await fixture.useCase(_params(fixture.context));

      expect(result.failureOrNull?.code, PaymentFailureCodes.permissionManage);
      expect(fixture.invoices.detailsCalls, 0);
      expect(fixture.payments.registerCalls, 0);
    });

    test(
      'zero amount is rejected in Domain before repository mutation',
      () async {
        final fixture = _Fixture();

        final result = await fixture.useCase(
          _params(fixture.context, amountText: '0'),
        );

        expect(
          result.failureOrNull?.code,
          PaymentFailureCodes.validationAmountPositive,
        );
        expect(fixture.payments.registerCalls, 0);
      },
    );

    test(
      'future payment date is rejected against company business date',
      () async {
        final fixture = _Fixture();

        final result = await fixture.useCase(
          _params(fixture.context, paymentDate: DateTime.utc(2026, 8, 11)),
        );

        expect(
          result.failureOrNull?.code,
          PaymentFailureCodes.validationDateFuture,
        );
        expect(fixture.businessDate.lastCompanyId, 'company-1');
        expect(fixture.payments.registerCalls, 0);
      },
    );

    test('inactive payment method is rejected explicitly', () async {
      final fixture = _Fixture(methodIsActive: false);

      final result = await fixture.useCase(_params(fixture.context));

      expect(
        result.failureOrNull?.code,
        PaymentFailureCodes.conflictPaymentMethodInactive,
      );
      expect(fixture.payments.registerCalls, 0);
    });

    test('overpayment is rejected from current persisted balance', () async {
      final fixture = _Fixture(
        invoiceStatus: InvoiceStatus.partiallyPaid,
        existingPayments: [_payment(amountMinorUnits: 40000)],
      );

      final result = await fixture.useCase(
        _params(fixture.context, amountText: '800.01'),
      );

      expect(
        result.failureOrNull?.code,
        PaymentFailureCodes.conflictOverpayment,
      );
      expect(fixture.payments.registerCalls, 0);
    });

    test(
      'valid payment is company scoped and remains exact minor units',
      () async {
        final fixture = _Fixture();

        final result = await fixture.useCase(
          _params(
            fixture.context,
            amountText: '400.00',
            referenceNumber: '  REF-1  ',
            notes: '  note  ',
          ),
        );

        expect(result, isA<Success<Payment>>());
        expect(fixture.payments.registerCalls, 1);
        expect(fixture.payments.lastCompanyId, 'company-1');
        expect(fixture.payments.lastInvoiceId, 'invoice-1');
        expect(fixture.payments.lastPaymentMethodId, 'method-1');
        expect(fixture.payments.lastAmount?.minorUnits, 40000);
        expect(fixture.payments.lastAmount?.currency.value, 'AED');
        expect(fixture.payments.lastReferenceNumber, 'REF-1');
        expect(fixture.payments.lastNotes, 'note');
      },
    );
  });

  group('GetPayableInvoicesUseCase', () {
    test('returns only invoices with a valid outstanding balance', () async {
      final invoices = _FakeInvoicesRepository(
        invoices: [
          _invoice(id: 'issued', status: InvoiceStatus.issued),
          _invoice(id: 'partial', status: InvoiceStatus.partiallyPaid),
          _invoice(id: 'paid', status: InvoiceStatus.paid),
          _invoice(id: 'cancelled', status: InvoiceStatus.cancelled),
        ],
      );
      final payments = _FakePaymentsRepository(
        payments: [
          _payment(invoiceId: 'partial', amountMinorUnits: 40000),
          _payment(invoiceId: 'paid', amountMinorUnits: 120000),
        ],
      );
      final useCase = GetPayableInvoicesUseCase(
        invoicesRepository: invoices,
        paymentsRepository: payments,
      );

      final result = await useCase(
        GetPayableInvoicesParams(
          currentCompanyContext: _context(CompanyRole.accountant),
        ),
      );

      expect(result.failureOrNull, isNull);
      final payable = result.dataOrNull!;
      expect(payable.map((item) => item.invoice.id), ['issued', 'partial']);
      expect(payable.last.balance.paid.minorUnits, 40000);
      expect(payable.last.balance.remaining.minorUnits, 80000);
    });
  });
}

RegisterPaymentParams _params(
  CurrentCompanyContext context, {
  String amountText = '100.00',
  DateTime? paymentDate,
  String? referenceNumber,
  String? notes,
}) {
  return RegisterPaymentParams(
    currentCompanyContext: context,
    invoiceId: 'invoice-1',
    paymentMethodId: 'method-1',
    paymentDate: paymentDate ?? DateTime.utc(2026, 8, 10),
    amountText: amountText,
    referenceNumber: referenceNumber,
    notes: notes,
  );
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
      businessTimezone: 'Asia/Dubai',
    ),
    role: role,
  );
}

Invoice _invoice({
  String id = 'invoice-1',
  InvoiceStatus status = InvoiceStatus.issued,
}) {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final total = Money(minorUnits: 120000, currency: currency);
  return Invoice(
    id: id,
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer',
    ),
    status: status,
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

Payment _payment({
  String invoiceId = 'invoice-1',
  int amountMinorUnits = 40000,
}) {
  final currency = CurrencyCode.tryParse('AED')!;
  return Payment(
    id: 'payment-$invoiceId-$amountMinorUnits',
    companyId: 'company-1',
    invoiceId: invoiceId,
    customerId: 'customer-1',
    paymentMethodId: 'method-1',
    paymentDate: DateTime.utc(2026, 8, 10),
    amount: Money(minorUnits: amountMinorUnits, currency: currency),
    createdAt: DateTime.utc(2026, 8, 10),
  );
}

final class _Fixture {
  late final CurrentCompanyContext context;
  late final _FakeInvoicesRepository invoices;
  late final _FakePaymentsRepository payments;
  late final _FakePaymentMethodsRepository methods;
  late final _FixedBusinessDateProvider businessDate;
  late final RegisterPaymentUseCase useCase;

  _Fixture({
    CompanyRole role = CompanyRole.accountant,
    InvoiceStatus invoiceStatus = InvoiceStatus.issued,
    bool methodIsActive = true,
    List<Payment> existingPayments = const [],
  }) {
    context = _context(role);
    invoices = _FakeInvoicesRepository(
      invoices: [_invoice(status: invoiceStatus)],
    );
    payments = _FakePaymentsRepository(payments: existingPayments);
    methods = _FakePaymentMethodsRepository(
      methods: [
        PaymentMethod(
          id: 'method-1',
          companyId: 'company-1',
          name: 'Cash',
          isActive: methodIsActive,
        ),
      ],
    );
    businessDate = _FixedBusinessDateProvider(DateTime.utc(2026, 8, 10));
    useCase = RegisterPaymentUseCase(
      paymentsRepository: payments,
      invoicesRepository: invoices,
      paymentMethodsRepository: methods,
      businessDateProvider: businessDate,
    );
  }
}

final class _FixedBusinessDateProvider implements CompanyBusinessDateProvider {
  final DateTime value;
  String? lastCompanyId;

  _FixedBusinessDateProvider(this.value);

  @override
  Future<Result<DateTime>> getBusinessDate({required String companyId}) async {
    lastCompanyId = companyId;
    return Success<DateTime>(value);
  }
}

final class _FakePaymentsRepository implements PaymentsRepository {
  final List<Payment> payments;
  int registerCalls = 0;
  String? lastCompanyId;
  String? lastInvoiceId;
  String? lastPaymentMethodId;
  Money? lastAmount;
  String? lastReferenceNumber;
  String? lastNotes;

  _FakePaymentsRepository({this.payments = const []});

  @override
  Future<Result<List<Payment>>> getPayments({required String companyId}) async {
    lastCompanyId = companyId;
    return Success<List<Payment>>(List.of(payments));
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) async {
    lastCompanyId = companyId;
    lastInvoiceId = invoiceId;
    return Success<List<Payment>>(
      payments.where((payment) => payment.invoiceId == invoiceId).toList(),
    );
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
    lastCompanyId = companyId;
    lastInvoiceId = invoiceId;
    lastPaymentMethodId = paymentMethodId;
    lastAmount = amount;
    lastReferenceNumber = referenceNumber;
    lastNotes = notes;
    return Success<Payment>(
      Payment(
        id: 'created-payment',
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
  final List<Invoice> invoices;
  int detailsCalls = 0;

  _FakeInvoicesRepository({required this.invoices});

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) async {
    return Success<List<Invoice>>(List.of(invoices));
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    detailsCalls++;
    return Success<Invoice>(
      invoices.firstWhere((invoice) => invoice.id == invoiceId),
    );
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
  final List<PaymentMethod> methods;

  _FakePaymentMethodsRepository({required this.methods});

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) async => Success<List<PaymentMethod>>(List.of(methods));

  @override
  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  }) async => Success<List<PaymentMethod>>(
    methods.where((method) => method.isActive).toList(),
  );

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
