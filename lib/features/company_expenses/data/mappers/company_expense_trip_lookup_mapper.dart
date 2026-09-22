import '../models/company_expense_link_option_model.dart';
import '../models/company_expense_trip_lookup_model.dart';

extension CompanyExpenseTripLookupModelMapper on CompanyExpenseTripLookupModel {
  CompanyExpenseLinkOptionModel toLinkOption() {
    return CompanyExpenseLinkOptionModel(id: id, label: _displayLabel);
  }

  String get _displayLabel {
    final reference = _text(tripNumber);
    final customer = _text(customerName);
    final route = _routeLabel;
    final context = [customer, route]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' - ');

    if (reference != null && context.isNotEmpty) {
      return '$reference - $context';
    }

    if (reference != null) return reference;

    final orderNumber = _text(loadingOrderNumber);
    if (orderNumber != null) return orderNumber;

    final waybill = _text(waybillNumber);
    if (waybill != null) return waybill;

    if (context.isNotEmpty) return context;

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
