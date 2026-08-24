import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/payments/data/constants/payments_db_constants.dart';
import 'package:horus_system/features/payments/data/datasources/payments_remote_data_source.dart';
import 'package:horus_system/features/payments/data/models/payment_model.dart';
import 'package:horus_system/features/payments/data/repositories/payments_repository_impl.dart';
import 'package:horus_system/features/payments/domain/failures/payment_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('PaymentsRepositoryImpl', () {
    test(
      'maps payment models into domain entities on company-scoped read',
      () async {
        final dataSource = _FakePaymentsRemoteDataSource(
          payments: [_paymentModel()],
        );
        final repository = PaymentsRepositoryImpl(dataSource);

        final result = await repository.getPayments(companyId: 'company-1');

        expect(result.failureOrNull, isNull);
        expect(result.dataOrNull?.single.id, 'payment-1');
        expect(result.dataOrNull?.single.amount.minorUnits, 40000);
        expect(dataSource.lastCompanyId, 'company-1');
      },
    );

    test(
      'preserves company and invoice scope on invoice payment read',
      () async {
        final dataSource = _FakePaymentsRemoteDataSource(
          payments: [_paymentModel()],
        );
        final repository = PaymentsRepositoryImpl(dataSource);

        final result = await repository.getPaymentsForInvoice(
          companyId: 'company-1',
          invoiceId: 'invoice-1',
        );

        expect(result.failureOrNull, isNull);
        expect(result.dataOrNull?.single.id, 'payment-1');
        expect(dataSource.lastCompanyId, 'company-1');
        expect(dataSource.lastInvoiceId, 'invoice-1');
      },
    );

    test(
      'register delegates exact arguments and maps returned payment',
      () async {
        final dataSource = _FakePaymentsRemoteDataSource(
          registeredPayment: _paymentModel(),
        );
        final repository = PaymentsRepositoryImpl(dataSource);
        final currency = CurrencyCode.tryParse('AED')!;
        final paymentDate = DateTime.utc(2026, 8, 10);
        final amount = Money(minorUnits: 40000, currency: currency);

        final result = await repository.registerPayment(
          companyId: 'company-1',
          invoiceId: 'invoice-1',
          paymentMethodId: 'method-1',
          paymentDate: paymentDate,
          amount: amount,
          referenceNumber: 'REF-1',
          notes: 'Paid by bank transfer',
        );

        expect(result.failureOrNull, isNull);
        expect(result.dataOrNull?.id, 'payment-1');
        expect(dataSource.lastCompanyId, 'company-1');
        expect(dataSource.lastInvoiceId, 'invoice-1');
        expect(dataSource.lastPaymentMethodId, 'method-1');
        expect(dataSource.lastPaymentDate, paymentDate);
        expect(dataSource.lastAmount, same(amount));
        expect(dataSource.lastReferenceNumber, 'REF-1');
        expect(dataSource.lastNotes, 'Paid by bank transfer');
      },
    );

    test('uses view permission code for payment reads', () async {
      final repository = PaymentsRepositoryImpl(
        _FakePaymentsRemoteDataSource(
          nextError: const PostgrestException(
            message: 'permission denied',
            code: PaymentsRpcErrorCodes.permissionDenied,
          ),
        ),
      );

      final result = await repository.getPayments(companyId: 'company-1');

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(result.failureOrNull?.code, PaymentFailureCodes.permissionView);
    });

    test('uses manage permission code for payment registration', () async {
      final repository = PaymentsRepositoryImpl(
        _FakePaymentsRemoteDataSource(
          nextError: const PostgrestException(
            message: 'permission denied',
            code: PaymentsRpcErrorCodes.permissionDenied,
          ),
        ),
      );
      final currency = CurrencyCode.tryParse('AED')!;

      final result = await repository.registerPayment(
        companyId: 'company-1',
        invoiceId: 'invoice-1',
        paymentMethodId: 'method-1',
        paymentDate: DateTime.utc(2026, 8, 10),
        amount: Money(minorUnits: 40000, currency: currency),
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(result.failureOrNull?.code, PaymentFailureCodes.permissionManage);
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

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        PaymentFailureCodes.conflictOverpayment,
      );
      expect(result.failureOrNull?.message, isNull);
    });

    test(
      'maps auth exceptions to the existing auth-required failure',
      () async {
        final repository = PaymentsRepositoryImpl(
          _FakePaymentsRemoteDataSource(nextError: AuthException('expired')),
        );

        final result = await repository.getPayments(companyId: 'company-1');

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
        expect(result.failureOrNull?.message, isNull);
      },
    );

    test('keeps model mapping inside corrupt-data failure boundary', () async {
      final repository = PaymentsRepositoryImpl(
        _FakePaymentsRemoteDataSource(
          payments: [_paymentModel(amountMinorUnits: 0)],
        ),
      );

      final result = await repository.getPayments(companyId: 'company-1');

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected failures without exposing internal text', () async {
      final repository = PaymentsRepositoryImpl(
        _FakePaymentsRemoteDataSource(
          nextError: StateError('secret internal text'),
        ),
      );

      final result = await repository.getPaymentsForInvoice(
        companyId: 'company-1',
        invoiceId: 'invoice-1',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

PaymentModel _paymentModel({
  int amountMinorUnits = 40000,
  String currencyCode = 'AED',
}) {
  return PaymentModel(
    id: 'payment-1',
    companyId: 'company-1',
    invoiceId: 'invoice-1',
    customerId: 'customer-1',
    paymentMethodId: 'method-1',
    paymentDate: DateTime.utc(2026, 8, 10),
    amountMinorUnits: amountMinorUnits,
    currencyCode: currencyCode,
    referenceNumber: 'REF-1',
    notes: 'Paid by bank transfer',
    createdAt: DateTime.utc(2026, 8, 10),
  );
}

final class _FakePaymentsRemoteDataSource implements PaymentsRemoteDataSource {
  final List<PaymentModel> payments;
  final PaymentModel? registeredPayment;
  final Object? nextError;

  String? lastCompanyId;
  String? lastInvoiceId;
  String? lastPaymentMethodId;
  DateTime? lastPaymentDate;
  Money? lastAmount;
  String? lastReferenceNumber;
  String? lastNotes;

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
    lastPaymentMethodId = paymentMethodId;
    lastPaymentDate = paymentDate;
    lastAmount = amount;
    lastReferenceNumber = referenceNumber;
    lastNotes = notes;
    return registeredPayment ?? _paymentModel();
  }

  void _throwIfNeeded() {
    final error = nextError;
    if (error != null) throw error;
  }
}
