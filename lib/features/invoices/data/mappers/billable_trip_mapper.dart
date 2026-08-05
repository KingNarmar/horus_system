import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../../trips/domain/entities/trip_status.dart';
import '../../domain/entities/billable_trip.dart';
import '../models/billable_trip_model.dart';

extension BillableTripModelMapper on BillableTripModel {
  BillableTrip toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw FormatException(
        'Invalid persisted invoice currency: $currencyCode.',
      );
    }

    TripStatus? parsedStatus;
    for (final candidate in TripStatus.values) {
      if (candidate.value == status) {
        parsedStatus = candidate;
        break;
      }
    }
    if (parsedStatus == null) {
      throw FormatException('Invalid persisted trip status: $status.');
    }

    return BillableTrip(
      id: id,
      companyId: companyId,
      customerId: customerId,
      status: parsedStatus,
      freightAmount: Money(minorUnits: freightMinorUnits, currency: currency),
      isAlreadyInvoiced: isAlreadyInvoiced,
      loadingOrderNumber: loadingOrderNumber,
      waybillNumber: waybillNumber,
      serviceDate: serviceDate,
      quantityTons: quantityTons,
    );
  }
}
