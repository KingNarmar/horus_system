import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/customer_statement_movement.dart';
import '../../domain/entities/customer_statement_movement_type.dart';
import '../../domain/entities/customer_statement_source.dart';
import '../models/customer_statement_source_model.dart';

extension CustomerStatementSourceModelMapper on CustomerStatementSourceModel {
  CustomerStatementSource toEntity() {
    final baseCurrency = _currency(baseCurrencyCode);

    return CustomerStatementSource(
      companyId: companyId,
      customerId: customerId,
      customerName: customerName,
      customerIsActive: customerIsActive,
      baseCurrency: baseCurrency,
      baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      businessTimezone: businessTimezone,
      fromDate: fromDate,
      toDate: toDate,
      openingInvoiceAmounts: openingInvoices
          .map(
            (amount) => Money(
              minorUnits: amount.totalMinorUnits,
              currency: _currency(amount.currencyCode),
            ),
          )
          .toList(growable: false),
      openingPaymentAmounts: openingPayments
          .map(
            (amount) => Money(
              minorUnits: amount.totalMinorUnits,
              currency: _currency(amount.currencyCode),
            ),
          )
          .toList(growable: false),
      movements: movements
          .map(
            (movement) => CustomerStatementMovement(
              type: _movementType(movement.sourceType),
              sourceId: movement.sourceId,
              businessDate: movement.businessDate,
              eventTimestamp: movement.eventTimestamp,
              amount: Money(
                minorUnits: movement.amountMinorUnits,
                currency: _currency(movement.currencyCode),
              ),
              reference: movement.reference,
              relatedInvoiceId: movement.relatedInvoiceId,
            ),
          )
          .toList(growable: false),
    );
  }
}

CurrencyCode _currency(String raw) {
  final currency = CurrencyCode.tryParse(raw);
  if (currency == null) {
    throw FormatException('Invalid customer statement currency code.');
  }
  return currency;
}

CustomerStatementMovementType _movementType(String raw) {
  return switch (raw) {
    'invoice' => CustomerStatementMovementType.invoice,
    'payment' => CustomerStatementMovementType.payment,
    _ => throw FormatException('Invalid customer statement movement type.'),
  };
}
