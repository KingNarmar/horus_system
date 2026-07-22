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
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      loadingLocation: map['loading_location'] as String,
      unloadingLocation: map['unloading_location'] as String,
      governorateFrom: map['governorate_from'] as String?,
      governorateTo: map['governorate_to'] as String?,
      defaultFreightPrice: _toDouble(map['default_freight_price']),
      notes: map['notes'] as String?,
      isActive: map['is_active'] as bool? ?? true,
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
}
