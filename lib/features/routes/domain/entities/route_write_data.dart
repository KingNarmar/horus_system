class RouteWriteData {
  final String companyId;
  final String loadingLocation;
  final String unloadingLocation;
  final String? governorateFrom;
  final String? governorateTo;
  final double? defaultFreightPrice;
  final String? notes;

  const RouteWriteData({
    required this.companyId,
    required this.loadingLocation,
    required this.unloadingLocation,
    this.governorateFrom,
    this.governorateTo,
    this.defaultFreightPrice,
    this.notes,
  });
}
