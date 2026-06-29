import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/driver_financial_movement_write_data.dart';
import '../mappers/driver_financial_movement_mapper.dart';
import '../models/driver_financial_movement_model.dart';

const _driverFinancialMovementsTable = 'driver_financial_movements';

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

abstract class DriverFinanceRemoteDataSource {
  Future<List<DriverFinancialMovementModel>> getDriverMovements({
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
}
