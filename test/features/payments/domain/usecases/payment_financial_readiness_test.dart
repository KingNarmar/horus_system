import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_creation_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoices_repository.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method.dart';
import 'package:horus_system/features/payment_methods/domain/entities/payment_method_write_data.dart';
import 'package:horus_system/features/payment_methods/domain/repositories/payment_methods_repository.dart';
import 'package:horus_system/features/payments/domain/entities/payment.dart';
import 'package:horus_system/features/payments/domain/repositories/payments_repository.dart';
import 'package:horus_system/features/payments/domain/usecases/payment_params.dart';
import 'package:horus_system/features/payments/domain/usecases/payment_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('Payments financial readiness', () {
    test('payment list fails before repository access when currency is missing', () async {
      final payments = _TrackingPaymentsRepository();
      final result = await GetPaymentsUseCase(payments)(
        GetPaymentsParams(currentCompanyContext: _contextWithoutCurrency()),
      );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
      expect(payments.getPaymentsCalls, 0);
    });

    test(
      'payable invoices fail before invoice or payment reads when currency is missing',
      () async {
        final invoices = _TrackingInvoicesRepository();
        final payments = _TrackingPaymentsRepository();
        final result = await GetPayableInvoicesUseCase(
          invoicesRepository: invoices,
          paymentsRepository: payments,
        )(
          GetPayableInvoicesParams(
            currentCompanyContext: _contextWithoutCurrency(),
          ),
        );

        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        );
        expect(invoices.getInvoicesCalls, 0);
        expect(payments.getPaymentsCalls, 0);
      },
    );

    test(
      'payment registration fails before financial repository access when currency is missing',
      () async {
        final invoices = _TrackingInvoicesRepository();
        final payments = _TrackingPaymentsRepository();
        final methods = _TrackingPaymentMethodsRepository();
        final businessDate = _TrackingBusinessDateProvider();
        final useCase = RegisterPaymentUseCase(
          paymentsRepository: payments,
          invoicesRepository: invoices,
          paymentMethodsRepository: methods,
          businessDateProvider: businessDate,
        );

        final result = await useCase(
          RegisterPaymentParams(
            currentCompanyContext: _contextWithoutCurrency(),
            invoiceId: 'invoice-1',
            paymentMethodId: 'method-1',
            paymentDate: BusinessDate(year: 2026, month: 9, day: 9),
            amountText: '100.00',
          ),
        );

        expect(
          result.failureOrNull?.code,
          CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        );
        expect(invoices.detailsCalls, 0);
        expect(payments.getPaymentsForInvoiceCalls, 0);
        expect(payments.registerCalls, 0);
        expect(methods.getMethodsCalls, 0);
        expect(businessDate.calls, 0);
      },
    );
  });
}

CurrentCompanyContext _contextWithoutCurrency() {
  return const CurrentCompanyContext(
    company: Company(
      id: 'company-1',
      name: 'Horus Transport',
      businessTimezone: 'Asia/Dubai',
    ),
    role: CompanyRole.accountant,
  );
}

final class _TrackingPaymentsRepository implements PaymentsRepository {
  int getPaymentsCalls = 0;
  int getPaymentsForInvoiceCalls = 0;
  int registerCalls = 0;

  @override
  Future<Result<List<Payment>>> getPayments({required String companyId}) async {
    getPaymentsCalls++;
    return const Success<List<Payment>>([]);
  }

  @override
  Future<Result<List<Payment>>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) async {
    getPaymentsForInvoiceCalls++;
    return const Success<List<Payment>>([]);
  }

  @override
  Future<Result<Payment>> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required BusinessDate paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  }) {
    registerCalls++;
    throw StateError('Unexpected payment registration.');
  }
}

final class _TrackingInvoicesRepository implements InvoicesRepository {
  int getInvoicesCalls = 0;
  int detailsCalls = 0;

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) async {
    getInvoicesCalls++;
    return const Success<List<Invoice>>([]);
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) {
    detailsCalls++;
    throw StateError('Unexpected invoice details read.');
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

final class _TrackingPaymentMethodsRepository
    implements PaymentMethodsRepository {
  int getMethodsCalls = 0;

  @override
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  }) async {
    getMethodsCalls++;
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

final class _TrackingBusinessDateProvider implements CompanyBusinessDateProvider {
  int calls = 0;

  @override
  Future<Result<BusinessDate>> getBusinessDate({required String companyId}) async {
    calls++;
    return Success(BusinessDate(year: 2026, month: 9, day: 9));
  }
}
