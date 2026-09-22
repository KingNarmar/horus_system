import '../models/company_expense_link_option_model.dart';
import '../models/company_expense_trip_lookup_model.dart';

extension CompanyExpenseTripLookupModelMapper
    on CompanyExpenseTripLookupModel {
  CompanyExpenseLinkOptionModel toLinkOption() {
    return CompanyExpenseLinkOptionModel(id: id, label: _displayLabel);
  }

  String get _displayLabel {
    final orderNumber = _text(loadingOrderNumber);
    if (orderNumber != null) return orderNumber;

    final waybill = _text(waybillNumber);
    if (waybill != null) return waybill;

    final customer = _text(customerName);
    final route = _routeLabel;

    if (customer != null && route != null) {
      return '$customer - $route';
    }

    if (customer != null) return customer;
    if (route != null) return route;

    return id;
  }

  String? get _routeLabel {
    final loading = _text(routeLoadingLocation);
    final unloading = _text(routeUnloadingLocation);
    if (loading == null || unloading == null) return null;
    return '$loading -> $unloading';
  }
}

String? _text(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
