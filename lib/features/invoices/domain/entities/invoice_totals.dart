import '../../../../core/domain/value_objects/money.dart';
import '../value_objects/tax_rate.dart';

final class InvoiceTotals {
  final Money subtotal;
  final Money discount;
  final Money taxableAmount;
  final TaxRate taxRate;
  final Money taxAmount;
  final Money grandTotal;

  const InvoiceTotals({
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.grandTotal,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is InvoiceTotals &&
            other.subtotal == subtotal &&
            other.discount == discount &&
            other.taxableAmount == taxableAmount &&
            other.taxRate == taxRate &&
            other.taxAmount == taxAmount &&
            other.grandTotal == grandTotal;
  }

  @override
  int get hashCode => Object.hash(
    subtotal,
    discount,
    taxableAmount,
    taxRate,
    taxAmount,
    grandTotal,
  );
}
