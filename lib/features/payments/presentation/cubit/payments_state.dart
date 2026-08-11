import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../domain/entities/payment.dart';

sealed class PaymentsState {
  const PaymentsState();
}

final class PaymentsInitial extends PaymentsState {
  const PaymentsInitial();
}

final class PaymentsLoading extends PaymentsState {
  const PaymentsLoading();
}

final class PaymentsFailure extends PaymentsState {
  final Failure failure;

  const PaymentsFailure(this.failure);
}

final class PaymentsLoaded extends PaymentsState {
  final CurrentCompanyContext currentCompanyContext;
  final List<Payment> allPayments;
  final List<Invoice> invoices;
  final List<PaymentMethod> paymentMethods;
  final bool canRegisterPayments;
  final String searchQuery;

  const PaymentsLoaded({
    required this.currentCompanyContext,
    required this.allPayments,
    required this.invoices,
    required this.paymentMethods,
    required this.canRegisterPayments,
    this.searchQuery = '',
  });

  List<Payment> get visiblePayments {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return allPayments;

    return allPayments
        .where((payment) {
          final invoice = invoiceFor(payment);
          final method = paymentMethodFor(payment);
          final values = <String?>[
            payment.referenceNumber,
            payment.notes,
            payment.amount.currency.value,
            payment.amount.minorUnits.toString(),
            invoice?.number?.value,
            invoice?.customer.name,
            method?.name,
          ];
          return values.any(
            (value) => value?.toLowerCase().contains(query) ?? false,
          );
        })
        .toList(growable: false);
  }

  Invoice? invoiceFor(Payment payment) {
    for (final invoice in invoices) {
      if (invoice.id == payment.invoiceId) return invoice;
    }
    return null;
  }

  PaymentMethod? paymentMethodFor(Payment payment) {
    for (final method in paymentMethods) {
      if (method.id == payment.paymentMethodId) return method;
    }
    return null;
  }

  PaymentsLoaded copyWith({String? searchQuery}) {
    return PaymentsLoaded(
      currentCompanyContext: currentCompanyContext,
      allPayments: allPayments,
      invoices: invoices,
      paymentMethods: paymentMethods,
      canRegisterPayments: canRegisterPayments,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
