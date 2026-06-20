import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/trip_form_lookups.dart';
import '../../domain/entities/trip_lookup_option.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_write_data.dart';
import '../mappers/trip_mapper.dart';
import '../models/trip_model.dart';
import '../models/trip_status_history_model.dart';

const _tripsTable = 'trips';
const _tripStatusHistoryTable = 'trip_status_history';

const _customersTable = 'customers';
const _routesTable = 'routes';
const _driversTable = 'drivers';
const _tractorHeadsTable = 'tractor_heads';
const _trailersTable = 'trailers';

const _openTripStatusFilter =
    'status.eq.created,status.eq.assigned,status.eq.loaded,status.eq.on_road,status.eq.arrived';

const _tripColumns = '''
id,
company_id,
customer_id,
route_id,
driver_id,
tractor_head_id,
trailer_id,
status,
loading_order_number,
waybill_number,
quantity_tons,
freight_price,
total_expenses,
scheduled_loading_at,
scheduled_delivery_at,
actual_loading_at,
actual_delivery_at,
notes,
created_at,
updated_at,
customers!trips_company_customer_fk(name),
routes!trips_company_route_fk(loading_location, unloading_location),
drivers!trips_company_driver_fk(full_name),
tractor_heads!trips_company_tractor_fk(plate_number),
trailers!trips_company_trailer_fk(plate_number)
''';

const _tripStatusHistoryColumns = '''
id,
company_id,
trip_id,
old_status,
new_status,
changed_by,
changed_by_name,
changed_by_role,
notes,
changed_at
''';

abstract class TripsRemoteDataSource {
  Future<List<TripModel>> getTrips({required String companyId});

  Future<TripModel> getTripById({
    required String companyId,
    required String id,
  });

  Future<TripFormLookups> getTripFormLookups({required String companyId});

  Future<TripModel> createTrip({required TripWriteData data});

  Future<TripModel> saveTrip({required String id, required TripWriteData data});

  Future<TripModel> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
  });

  Future<TripStatusHistoryModel> addTripStatusHistory({
    required String companyId,
    required String tripId,
    required TripStatus? oldStatus,
    required TripStatus newStatus,
    required String actorRole,
    String? notes,
  });

  Future<List<TripStatusHistoryModel>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  });

  Future<bool> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  });
}

class SupabaseTripsRemoteDataSource implements TripsRemoteDataSource {
  final SupabaseClient client;

  const SupabaseTripsRemoteDataSource(this.client);

  @override
  Future<List<TripModel>> getTrips({required String companyId}) async {
    final rows = await client
        .from(_tripsTable)
        .select(_tripColumns)
        .eq(DbCommonFields.companyId, companyId)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map((row) => TripModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<TripModel> getTripById({
    required String companyId,
    required String id,
  }) async {
    final row = await client
        .from(_tripsTable)
        .select(_tripColumns)
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .single();

    return TripModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripFormLookups> getTripFormLookups({
    required String companyId,
  }) async {
    final results = await Future.wait<List<TripLookupOption>>([
      _getSimpleLookupOptions(
        companyId: companyId,
        table: _customersTable,
        labelColumn: 'name',
        orderColumn: 'name',
      ),
      _getRouteLookupOptions(companyId: companyId),
      _getSimpleLookupOptions(
        companyId: companyId,
        table: _driversTable,
        labelColumn: 'full_name',
        orderColumn: 'full_name',
      ),
      _getSimpleLookupOptions(
        companyId: companyId,
        table: _tractorHeadsTable,
        labelColumn: 'plate_number',
        orderColumn: 'plate_number',
      ),
      _getSimpleLookupOptions(
        companyId: companyId,
        table: _trailersTable,
        labelColumn: 'plate_number',
        orderColumn: 'plate_number',
      ),
    ]);

    return TripFormLookups(
      customers: results[0],
      routes: results[1],
      drivers: results[2],
      tractorHeads: results[3],
      trailers: results[4],
    );
  }

  @override
  Future<TripModel> createTrip({required TripWriteData data}) async {
    final row = await client
        .from(_tripsTable)
        .insert(data.toInsertMap())
        .select(_tripColumns)
        .single();

    return TripModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
  }) async {
    final row = await client
        .from(_tripsTable)
        .update(data.toUpdateMap())
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(_tripColumns)
        .single();

    return TripModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripModel> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
  }) async {
    final row = await client
        .from(_tripsTable)
        .update(newStatus.toTripStatusUpdateMap())
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .select(_tripColumns)
        .single();

    return TripModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripStatusHistoryModel> addTripStatusHistory({
    required String companyId,
    required String tripId,
    required TripStatus? oldStatus,
    required TripStatus newStatus,
    required String actorRole,
    String? notes,
  }) async {
    final row = await client
        .from(_tripStatusHistoryTable)
        .insert(
          newStatus.toHistoryInsertMap(
            companyId: companyId,
            tripId: tripId,
            oldStatus: oldStatus,
            actorRole: actorRole,
            notes: notes,
          ),
        )
        .select(_tripStatusHistoryColumns)
        .single();

    return TripStatusHistoryModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<TripStatusHistoryModel>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) async {
    final rows = await client
        .from(_tripStatusHistoryTable)
        .select(_tripStatusHistoryColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq('trip_id', tripId)
        .order('changed_at', ascending: false);

    return rows
        .map(
          (row) =>
              TripStatusHistoryModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<bool> hasOpenTripForVehicle({
    required String companyId,
    String? tractorHeadId,
    String? trailerId,
    String? excludingTripId,
  }) async {
    if (tractorHeadId != null) {
      final hasOpenTractorTrip = await _hasOpenTripForSingleVehicle(
        companyId: companyId,
        column: 'tractor_head_id',
        vehicleId: tractorHeadId,
        excludingTripId: excludingTripId,
      );

      if (hasOpenTractorTrip) return true;
    }

    if (trailerId != null) {
      final hasOpenTrailerTrip = await _hasOpenTripForSingleVehicle(
        companyId: companyId,
        column: 'trailer_id',
        vehicleId: trailerId,
        excludingTripId: excludingTripId,
      );

      if (hasOpenTrailerTrip) return true;
    }

    return false;
  }

  Future<List<TripLookupOption>> _getSimpleLookupOptions({
    required String companyId,
    required String table,
    required String labelColumn,
    required String orderColumn,
  }) async {
    final rows = await client
        .from(table)
        .select('id, $labelColumn')
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(orderColumn);

    final options = <TripLookupOption>[];

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final label = map[labelColumn]?.toString().trim() ?? '';

      if (label.isEmpty) continue;

      options.add(
        TripLookupOption(id: map[DbCommonFields.id] as String, label: label),
      );
    }

    return options;
  }

  Future<List<TripLookupOption>> _getRouteLookupOptions({
    required String companyId,
  }) async {
    final rows = await client
        .from(_routesTable)
        .select('id, loading_location, unloading_location')
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order('loading_location');

    final options = <TripLookupOption>[];

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final loading = map['loading_location']?.toString().trim() ?? '';
      final unloading = map['unloading_location']?.toString().trim() ?? '';

      if (loading.isEmpty && unloading.isEmpty) continue;

      options.add(
        TripLookupOption(
          id: map[DbCommonFields.id] as String,
          label: '$loading -> $unloading',
        ),
      );
    }

    return options;
  }

  Future<bool> _hasOpenTripForSingleVehicle({
    required String companyId,
    required String column,
    required String vehicleId,
    String? excludingTripId,
  }) async {
    if (excludingTripId == null) {
      final rows = await client
          .from(_tripsTable)
          .select(DbCommonFields.id)
          .eq(DbCommonFields.companyId, companyId)
          .eq(column, vehicleId)
          .or(_openTripStatusFilter)
          .limit(1);

      return rows.isNotEmpty;
    }

    final rows = await client
        .from(_tripsTable)
        .select(DbCommonFields.id)
        .eq(DbCommonFields.companyId, companyId)
        .eq(column, vehicleId)
        .neq(DbCommonFields.id, excludingTripId)
        .or(_openTripStatusFilter)
        .limit(1);

    return rows.isNotEmpty;
  }
}
