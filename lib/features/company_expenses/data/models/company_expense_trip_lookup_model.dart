import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/company_expense_db_fields.dart';

final class CompanyExpenseTripLookupModel {
  final String id;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final String? customerName;
  final String? routeLoadingLocation;
  final String? routeUnloadingLocation;

  const CompanyExpenseTripLookupModel({
    required this.id,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.customerName,
    this.routeLoadingLocation,
    this.routeUnloadingLocation,
  });

  factory CompanyExpenseTripLookupModel.fromMap(Map<String, dynamic> map) {
    final customer = _nestedMap(
      map[CompanyExpenseLookupDbFields.customersTableName],
    );
    final route = _nestedMap(map[CompanyExpenseLookupDbFields.routesTableName]);

    return CompanyExpenseTripLookupModel(
      id: map[DbCommonFields.id] as String,
      loadingOrderNumber: _text(
        map[CompanyExpenseLookupDbFields.loadingOrderNumber],
      ),
      waybillNumber: _text(map[CompanyExpenseLookupDbFields.waybillNumber]),
      customerName: _text(customer?[CompanyExpenseLookupDbFields.name]),
      routeLoadingLocation: _text(
        route?[CompanyExpenseLookupDbFields.loadingLocation],
      ),
      routeUnloadingLocation: _text(
        route?[CompanyExpenseLookupDbFields.unloadingLocation],
      ),
    );
  }
}

Map<dynamic, dynamic>? _nestedMap(Object? value) {
  return value is Map ? value : null;
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
