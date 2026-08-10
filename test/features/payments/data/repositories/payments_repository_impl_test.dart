import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/features/payments/data/constants/payments_db_constants.dart';
import 'package:horus_system/features/payments/data/datasources/payments_remote_data_source.dart';
import 'package:horus_system/features/payments/data/models/payment_model.dart';
import 'package:horus_system/features/payments/data/repositories/payments_repository_impl.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('maps payment models into domain entities on company-scoped read', () async {
    final dataSource = _FakePaymentsRemoteDataSource(
      payments: [_paymentModel()],
    );
    final repository = PaymentsRepositoryImpl(dataSource);

    final result = await repository.getPayments(companyId: 'company-1');

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull?.single.id, 'payment-1');
    expect(result.dataOrNull?.single.amount.minorUnits, 40000);
    expect(dataSource.lastCompanyId, 'company-1');
  });

  test('register delegates exact minor units and maps returned payment', () async {
    final dataSource = _FakePaymentsRemoteDataSource(
      registeredPayment: _paymentModel(),
    );
    final repository = PaymentsRepositoryImpl(dataSource);
    final currency = CurrencyCode.tryParse('AED')!;

    final result = await repository.registerPayment(
      companyId: 'company-1',
      invoiceId: 'invoice-1',
      paymentMethodId: 'method-1',
      paymentDate: DateTime.utc(2026, 8, 10),
      amount: Money(minorUnits: 40000, currency: currency),
      referenceNumber: 'REF-1',
    );

    expect(result.failureOrNull, isNull);
    expect(result.dataOrNull?.id, 'payment-1');
    expect(dataSource.lastAmount?.minorUnits, 40000);
    expect(dataSource.lastInvoiceId, 'invoice-1');
  });

  test('maps RPC overpayment to typed conflict failure', () async {
    final dataSource = _FakePaymentsRemoteDataSource(
      nextError: const PostgrestException(
        message: 'payment_overpayment',
        code: PaymentsRpcErrorCodes.overpayment,
      ),
    );
    final repository = PaymentsRepositoryImpl(dataSource);
    final currency = CurrencyCode.tryParse('AED')!;

    final result = await repository.registerPayment(
      companyId: 'company-1',
      invoiceId: 'invoice-1',
      paymentMethodId: 'method-1',
      paymentDate: DateTime.utc(2026, 8, 10),
      amount: Money(minorUnits: 120001, currency: currency),
    );

    expect(result.failureOrNull?.code, PaymentFailureCodes.conflictOverpayment);
    expect(result.failureOrNull?.message, isNull);
  });
}

PaymentModel _paymentModel() {
  return PaymentModel(
    id: 'payment-1',
    companyId: 'company-1',
    invoiceId: 'invoice-1',
    customerId: 'customer-1',
    paymentMethodId: 'method-1',
    paymentDate: DateTime.utc(2026, 8, 10),
    amountMinorUnits: 40000,
    currencyCode: 'AED',
    referenceNumber: 'REF-1',
    createdAt: DateTime.utc(2026, 8, 10),
  );
}

final class _FakePaymentsRemoteDataSource implements PaymentsRemoteDataSource {
  final List<PaymentModel> payments;
  final PaymentModel? registeredPayment;
  final PostgrestException? nextError;

  String? lastCompanyId;
  String? lastInvoiceId;
  Money? lastAmount;

  _FakePaymentsRemoteDataSource({
    this.payments = const [],
    this.registeredPayment,
    this.nextError,
  });

  @override
  Future<List<PaymentModel>> getPayments({required String companyId}) async {
    _throwIfNeeded();
    lastCompanyId = companyId;
    return List.of(payments);
  }

  @override
  Future<List<PaymentModel>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) async {
    _throwIfNeeded();
    lastCompanyId = companyId;
    lastInvoiceId = invoiceId;
    return payments
        .where((payment) => payment.invoiceId == invoiceId)
        .toList(growable: false);
  }

  @override
  Future<PaymentModel> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  }) async {
    _throwIfNeeded();
    lastCompanyId = companyId;
    lastInvoiceId = invoiceId;
    lastAmount = amount;
    return registeredPayment ?? _paymentModel();
  }

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) throw error;
  }
}
