class RouteEntity {
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

  const RouteEntity({
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

  String get displayName => '$loadingLocation → $unloadingLocation';
}
