import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/invoice_trip_line.dart';
import '../models/invoice_trip_line_model.dart';

extension InvoiceTripLineModelMapper on InvoiceTripLineModel {
  InvoiceTripLine toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException(
        'Invalid persisted invoice currency: $currencyCode.',
      );
    }

    return InvoiceTripLine(
      tripId: tripId,
      loadingOrderNumber: loadingOrderNumber,
      waybillNumber: waybillNumber,
      serviceDate: serviceDate,
      quantityTons: quantityTons,
      amount: Money(minorUnits: amountMinorUnits, currency: currency),
    );
  }
}
