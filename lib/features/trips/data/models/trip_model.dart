import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/trip_db_fields.dart';

class TripModel {
  final String id;
  final String companyId;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String status;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final double? quantityTons;
  final double? freightPrice;
  final double? totalExpenses;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;
  final String? customerName;
  final String? routeName;
  final String? driverName;
  final String? tractorHeadPlateNumber;
  final String? trailerPlateNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripModel({
    required this.id,
    required this.companyId,
    required this.customerId,
    required this.routeId,
    required this.status,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTons,
    this.freightPrice,
    this.totalExpenses,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
    this.customerName,
    this.routeName,
    this.driverName,
    this.tractorHeadPlateNumber,
    this.trailerPlateNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map[DbCommonFields.id] as String,
      companyId: map[DbCommonFields.companyId] as String,
      customerId: map[TripDbFields.customerId] as String,
      routeId: map[TripDbFields.routeId] as String,
      driverId: map[TripDbFields.driverId] as String?,
      tractorHeadId: map[TripDbFields.tractorHeadId] as String?,
      trailerId: map[TripDbFields.trailerId] as String?,
      status: map[TripDbFields.status] as String? ?? 'created',
      loadingOrderNumber: map[TripDbFields.loadingOrderNumber] as String?,
      waybillNumber: map[TripDbFields.waybillNumber] as String?,
      quantityTons: _toDouble(map[TripDbFields.quantityTons]),
      freightPrice: _toDouble(map[TripDbFields.freightPrice]),
      totalExpenses: _toDouble(map[TripDbFields.totalExpenses]),
      scheduledLoadingAt: _toDateTime(map[TripDbFields.scheduledLoadingAt]),
      scheduledDeliveryAt: _toDateTime(map[TripDbFields.scheduledDeliveryAt]),
      actualLoadingAt: _toDateTime(map[TripDbFields.actualLoadingAt]),
      actualDeliveryAt: _toDateTime(map[TripDbFields.actualDeliveryAt]),
      notes: map[TripDbFields.notes] as String?,
      customerName:
          map[TripDbFields.customerNameAlias] as String? ??
          _nestedString(
            map[TripDbFields.customerRelationKey],
            TripLookupDbFields.name,
          ) ??
          _nestedString(
            map[TripLookupDbFields.customersTableName],
            TripLookupDbFields.name,
          ),
      routeName:
          map[TripDbFields.routeNameAlias] as String? ??
          _routeDisplayName(map[TripDbFields.routeRelationKey]) ??
          _routeDisplayName(map[TripLookupDbFields.routesTableName]),
      driverName:
          map[TripDbFields.driverNameAlias] as String? ??
          _nestedString(
            map[TripDbFields.driverRelationKey],
            TripLookupDbFields.fullName,
          ) ??
          _nestedString(
            map[TripLookupDbFields.driversTableName],
            TripLookupDbFields.fullName,
          ),
      tractorHeadPlateNumber:
          map[TripDbFields.tractorHeadPlateNumberAlias] as String? ??
          _nestedString(
            map[TripDbFields.tractorHeadRelationKey],
            TripLookupDbFields.plateNumber,
          ) ??
          _nestedString(
            map[TripLookupDbFields.tractorHeadsTableName],
            TripLookupDbFields.plateNumber,
          ),
      trailerPlateNumber:
          map[TripDbFields.trailerPlateNumberAlias] as String? ??
          _nestedString(
            map[TripDbFields.trailerRelationKey],
            TripLookupDbFields.plateNumber,
          ) ??
          _nestedString(
            map[TripLookupDbFields.trailersTableName],
            TripLookupDbFields.plateNumber,
          ),
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

  static String? _nestedString(Object? value, String key) {
    if (value is! Map) return null;
    final nestedValue = value[key];
    if (nestedValue == null) return null;
    final text = nestedValue.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _routeDisplayName(Object? value) {
    if (value is! Map) return null;

    final loadingLocation =
        value[TripLookupDbFields.loadingLocation]?.toString().trim();
    final unloadingLocation =
        value[TripLookupDbFields.unloadingLocation]?.toString().trim();

    if (loadingLocation != null &&
        loadingLocation.isNotEmpty &&
        unloadingLocation != null &&
        unloadingLocation.isNotEmpty) {
      return '$loadingLocation -> $unloadingLocation';
    }

    return _nestedString(value, TripLookupDbFields.name);
  }
}
