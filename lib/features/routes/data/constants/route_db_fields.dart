import '../../../../core/data/constants/db_common_fields.dart';

abstract final class RouteDbFields {
  static const tableName = 'routes';

  static const loadingLocation = 'loading_location';
  static const unloadingLocation = 'unloading_location';
  static const governorateFrom = 'governorate_from';
  static const governorateTo = 'governorate_to';
  static const defaultFreightPrice = 'default_freight_price';
  static const notes = 'notes';

  static const allColumns =
      '${DbCommonFields.id}, ${DbCommonFields.companyId}, '
      '$loadingLocation, $unloadingLocation, $governorateFrom, $governorateTo, '
      '$defaultFreightPrice, $notes, ${DbCommonFields.isActive}, '
      '${DbCommonFields.createdAt}, ${DbCommonFields.updatedAt}';
}
