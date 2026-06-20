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
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      customerId: map['customer_id'] as String,
      routeId: map['route_id'] as String,
      driverId: map['driver_id'] as String?,
      tractorHeadId: map['tractor_head_id'] as String?,
      trailerId: map['trailer_id'] as String?,
      status: map['status'] as String? ?? 'created',
      loadingOrderNumber: map['loading_order_number'] as String?,
      waybillNumber: map['waybill_number'] as String?,
      quantityTons: _toDouble(map['quantity_tons']),
      freightPrice: _toDouble(map['freight_price']),
      totalExpenses: _toDouble(map['total_expenses']),
      scheduledLoadingAt: _toDateTime(map['scheduled_loading_at']),
      scheduledDeliveryAt: _toDateTime(map['scheduled_delivery_at']),
      actualLoadingAt: _toDateTime(map['actual_loading_at']),
      actualDeliveryAt: _toDateTime(map['actual_delivery_at']),
      notes: map['notes'] as String?,
      customerName:
          map['customer_name'] as String? ??
          _nestedString(map['customer'], 'name') ??
          _nestedString(map['customers'], 'name'),
      routeName:
          map['route_name'] as String? ??
          _routeDisplayName(map['route']) ??
          _routeDisplayName(map['routes']),
      driverName:
          map['driver_name'] as String? ??
          _nestedString(map['driver'], 'full_name') ??
          _nestedString(map['drivers'], 'full_name'),
      tractorHeadPlateNumber:
          map['tractor_head_plate_number'] as String? ??
          _nestedString(map['tractor_head'], 'plate_number') ??
          _nestedString(map['tractor_heads'], 'plate_number'),
      trailerPlateNumber:
          map['trailer_plate_number'] as String? ??
          _nestedString(map['trailer'], 'plate_number') ??
          _nestedString(map['trailers'], 'plate_number'),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
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

    final loadingLocation = value['loading_location']?.toString().trim();
    final unloadingLocation = value['unloading_location']?.toString().trim();

    if (loadingLocation != null &&
        loadingLocation.isNotEmpty &&
        unloadingLocation != null &&
        unloadingLocation.isNotEmpty) {
      return '$loadingLocation -> $unloadingLocation';
    }

    return _nestedString(value, 'name');
  }
}
