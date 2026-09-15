import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/trip_db_fields.dart';

final class TripLookupOptionModel {
  final String id;
  final String label;

  const TripLookupOptionModel({required this.id, required this.label});
}

final class TripRouteLookupOptionModel {
  final String id;
  final String label;
  final String? defaultFreightRatePerTonDecimal;

  const TripRouteLookupOptionModel({
    required this.id,
    required this.label,
    this.defaultFreightRatePerTonDecimal,
  });

  factory TripRouteLookupOptionModel.fromMap(Map<String, dynamic> map) {
    final loading =
        map[TripLookupDbFields.loadingLocation]?.toString().trim() ?? '';
    final unloading =
        map[TripLookupDbFields.unloadingLocation]?.toString().trim() ?? '';
    final rawRate = map[TripLookupDbFields.defaultFreightRatePerTon];
    final rateText = rawRate?.toString().trim();

    return TripRouteLookupOptionModel(
      id: map[DbCommonFields.id] as String,
      label: '$loading -> $unloading',
      defaultFreightRatePerTonDecimal:
          rateText == null || rateText.isEmpty ? null : rateText,
    );
  }
}

final class TripFormLookupsModel {
  final List<TripLookupOptionModel> customers;
  final List<TripRouteLookupOptionModel> routes;
  final List<TripLookupOptionModel> drivers;
  final List<TripLookupOptionModel> tractorHeads;
  final List<TripLookupOptionModel> trailers;

  const TripFormLookupsModel({
    required this.customers,
    required this.routes,
    required this.drivers,
    required this.tractorHeads,
    required this.trailers,
  });
}
