import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/route_db_fields.dart';

class RouteModel {
  final String id;
  final String companyId;
  final String loadingLocation;
  final String unloadingLocation;
  final String? governorateFrom;
  final String? governorateTo;
  final double? defaultFreightPrice;
  final String? notes;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RouteModel({
    required this.id,
    required this.companyId,
    required this.loadingLocation,
    required this.unloadingLocation,
    required this.isActive,
    this.governorateFrom,
    this.governorateTo,
    this.defaultFreightPrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      loadingLocation: map[RouteDbFields.loadingLocation] as String,
      unloadingLocation: map[RouteDbFields.unloadingLocation] as String,
      governorateFrom: map[RouteDbFields.governorateFrom] as String?,
      governorateTo: map[RouteDbFields.governorateTo] as String?,
      defaultFreightPrice: _toDouble(map[RouteDbFields.defaultFreightPrice]),
      notes: map[RouteDbFields.notes] as String?,
      isActive: map[DbCommonFields.isActive] as bool? ?? true,
      createdAt: _toDateTime(map[DbCommonFields.createdAt]),
      updatedAt: _toDateTime(map[DbCommonFields.updatedAt]),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
