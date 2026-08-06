import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/invoice_totals.dart';
import '../../domain/value_objects/tax_rate.dart';
import '../models/invoice_totals_model.dart';

extension InvoiceTotalsModelMapper on InvoiceTotalsModel {
  InvoiceTotals toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException(
        'Invalid persisted invoice currency: $currencyCode.',
      );
    }

    final taxRate = TaxRate.tryCreate(taxRateBasisPoints);
    if (taxRate == null) {
      throw FormatException(
        'Invalid persisted invoice tax rate: $taxRateBasisPoints.',
      );
    }

    Money money(int minorUnits) {
      return Money(minorUnits: minorUnits, currency: currency);
    }

    return InvoiceTotals(
      subtotal: money(subtotalMinorUnits),
      discount: money(discountMinorUnits),
      taxableAmount: money(taxableMinorUnits),
      taxRate: taxRate,
      taxAmount: money(taxMinorUnits),
      grandTotal: money(totalMinorUnits),
    );
  }
}
