import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/driver_financial_movement_write_data.dart';
import '../mappers/driver_financial_movement_mapper.dart';
import '../models/driver_finance_trip_option_model.dart';
import '../models/driver_financial_movement_model.dart';

const _driverFinancialMovementsTable = 'driver_financial_movements';
const _tripsTable = 'trips';

const _driverFinancialMovementColumns = '''
id,
company_id,
driver_id,
trip_id,
movement_type,
amount,
movement_date,
notes,
created_at,
updated_at
''';

const _driverTripOptionColumns = '''
id,
loading_order_number,
waybill_number,
scheduled_loading_at,
actual_loading_at,
customers!trips_company_customer_fk(name),
routes!trips_company_route_fk(loading_location, unloading_location)
''';

abstract class DriverFinanceRemoteDataSource {
  Future<List<DriverFinancialMovementModel>> getDriverMovements({
    required String companyId,
    required String driverId,
  });

  Future<List<DriverFinanceTripOptionModel>> getDriverTripOptions({
    required String companyId,
    required String driverId,
  });

  Future<DriverFinancialMovementModel> addDriverMovement({
    required DriverFinancialMovementWriteData data,
  });
}

class SupabaseDriverFinanceRemoteDataSource
    implements DriverFinanceRemoteDataSource {
  final SupabaseClient client;

  const SupabaseDriverFinanceRemoteDataSource(this.client);

  @override
  Future<List<DriverFinancialMovementModel>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) async {
    final rows = await client
        .from(_driverFinancialMovementsTable)
        .select(_driverFinancialMovementColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq('driver_id', driverId)
        .order('movement_date', ascending: false)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map(
          (row) => DriverFinancialMovementModel.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  @override
  Future<List<DriverFinanceTripOptionModel>> getDriverTripOptions({
    required String companyId,
    required String driverId,
  }) async {
    final rows = await client
        .from(_tripsTable)
        .select(_driverTripOptionColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq('driver_id', driverId)
        .order('scheduled_loading_at', ascending: false, nullsFirst: false)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows.map((row) {
      final map = Map<String, dynamic>.from(row);
      return DriverFinanceTripOptionModel(
        id: map[DbCommonFields.id] as String,
        label: _buildTripLabel(map),
      );
    }).toList();
  }

  @override
  Future<DriverFinancialMovementModel> addDriverMovement({
    required DriverFinancialMovementWriteData data,
  }) async {
    final row = await client
        .from(_driverFinancialMovementsTable)
        .insert(data.toInsertMap())
        .select(_driverFinancialMovementColumns)
        .single();

    return DriverFinancialMovementModel.fromMap(Map<String, dynamic>.from(row));
  }

  String _buildTripLabel(Map<String, dynamic> map) {
    final loadingOrder = _optional(map['loading_order_number']);
    final waybill = _optional(map['waybill_number']);
    final tripNumber = loadingOrder ?? waybill;

    final customer = _nestedValue(map, 'customers', 'name');
    final loading = _nestedValue(map, 'routes', 'loading_location');
    final unloading = _nestedValue(map, 'routes', 'unloading_location');
    final route = _joinNonEmpty([loading, unloading], ' -> ');
    final date = _dateOnly(
      _optional(map['actual_loading_at']) ?? _optional(map['scheduled_loading_at']),
    );

    final label = _joinNonEmpty([
      tripNumber,
      customer,
      route,
      date,
    ], ' - ');

    return label.isEmpty ? map[DbCommonFields.id] as String : label;
  }

  String _joinNonEmpty(List<String?> values, String separator) {
    return values.whereType<String>().where((value) => value.isNotEmpty).join(separator);
  }

  String? _nestedValue(
    Map<String, dynamic> map,
    String relationKey,
    String valueKey,
  ) {
    final nested = map[relationKey];
    if (nested is! Map) return null;
    return _optional(nested[valueKey]);
  }

  String? _optional(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? _dateOnly(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
