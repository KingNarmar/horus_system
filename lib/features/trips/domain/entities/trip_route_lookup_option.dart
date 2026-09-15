import '../../../../core/domain/value_objects/money.dart';
import 'trip_lookup_option.dart';

class TripRouteLookupOption extends TripLookupOption {
  final Money? defaultFreightRatePerTon;

  const TripRouteLookupOption({
    required super.id,
    required super.label,
    this.defaultFreightRatePerTon,
  });
}
