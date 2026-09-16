import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/constants/user_profile_db_fields.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_write_data.dart';
import '../constants/trip_db_fields.dart';
import '../mappers/trip_mapper.dart';
import '../models/trip_lookup_models.dart';
import '../models/trip_model.dart';
import '../models/trip_status_history_model.dart';

abstract class TripsRemoteDataSource {
  Future<List<TripModel>> getTrips({required String companyId});

  Future<TripModel> getTripById({
    required String companyId,
    required String id,
  });

  Future<TripFormLookupsModel> getTripFormLookups({required String companyId});

  Future<TripModel> createTrip({
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

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
        .from(TripDbFields.tableName)
        .select(TripDbFields.allColumns)
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
        .from(TripDbFields.tableName)
        .select(TripDbFields.allColumns)
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .single();

    return TripModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripFormLookupsModel> getTripFormLookups({
    required String companyId,
  }) async {
    final customers = await _getSimpleLookupOptions(
      companyId: companyId,
      table: TripLookupDbFields.customersTableName,
      labelColumn: TripLookupDbFields.name,
      orderColumn: TripLookupDbFields.name,
    );
    final routes = await _getRouteLookupOptions(companyId: companyId);
    final drivers = await _getSimpleLookupOptions(
      companyId: companyId,
      table: TripLookupDbFields.driversTableName,
      labelColumn: TripLookupDbFields.fullName,
      orderColumn: TripLookupDbFields.fullName,
    );
    final tractorHeads = await _getSimpleLookupOptions(
      companyId: companyId,
      table: TripLookupDbFields.tractorHeadsTableName,
      labelColumn: TripLookupDbFields.plateNumber,
      orderColumn: TripLookupDbFields.plateNumber,
    );
    final trailers = await _getSimpleLookupOptions(
      companyId: companyId,
      table: TripLookupDbFields.trailersTableName,
      labelColumn: TripLookupDbFields.plateNumber,
      orderColumn: TripLookupDbFields.plateNumber,
    );

    return TripFormLookupsModel(
      customers: customers,
      routes: routes,
      drivers: drivers,
      tractorHeads: tractorHeads,
      trailers: trailers,
    );
  }

  @override
  Future<TripModel> createTrip({
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    final row = await client
        .from(TripDbFields.tableName)
        .insert(
          data.toInsertMap(financialConfiguration: financialConfiguration),
        )
        .select(TripDbFields.allColumns)
        .single();

    return TripModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    final row = await client
        .from(TripDbFields.tableName)
        .update(
          data.toUpdateMap(financialConfiguration: financialConfiguration),
        )
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(TripDbFields.allColumns)
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
        .from(TripDbFields.tableName)
        .update(newStatus.toTripStatusUpdateMap())
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, companyId)
        .select(TripDbFields.allColumns)
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
    final insertMap = newStatus.toHistoryInsertMap(
      companyId: companyId,
      tripId: tripId,
      oldStatus: oldStatus,
      actorRole: actorRole,
      notes: notes,
    );

    final actorDisplayName = await _getCurrentActorDisplayName();
    if (actorDisplayName != null) {
      insertMap[TripStatusHistoryDbFields.changedByName] = actorDisplayName;
    }

    final row = await client
        .from(TripStatusHistoryDbFields.tableName)
        .insert(insertMap)
        .select(TripStatusHistoryDbFields.allColumns)
        .single();

    return TripStatusHistoryModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<List<TripStatusHistoryModel>> getTripStatusHistory({
    required String companyId,
    required String tripId,
  }) async {
    final rows = await client
        .from(TripStatusHistoryDbFields.tableName)
        .select(TripStatusHistoryDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(TripStatusHistoryDbFields.tripId, tripId)
        .order(TripStatusHistoryDbFields.changedAt, ascending: false);

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
        column: TripDbFields.tractorHeadId,
        vehicleId: tractorHeadId,
        excludingTripId: excludingTripId,
      );

      if (hasOpenTractorTrip) return true;
    }

    if (trailerId != null) {
      final hasOpenTrailerTrip = await _hasOpenTripForSingleVehicle(
        companyId: companyId,
        column: TripDbFields.trailerId,
        vehicleId: trailerId,
        excludingTripId: excludingTripId,
      );

      if (hasOpenTrailerTrip) return true;
    }

    return false;
  }

  Future<List<TripLookupOptionModel>> _getSimpleLookupOptions({
    required String companyId,
    required String table,
    required String labelColumn,
    required String orderColumn,
  }) async {
    final rows = await client
        .from(table)
        .select('${DbCommonFields.id}, $labelColumn')
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(orderColumn);

    final options = <TripLookupOptionModel>[];

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final label = map[labelColumn]?.toString().trim() ?? '';

      if (label.isEmpty) continue;

      options.add(
        TripLookupOptionModel(
          id: map[DbCommonFields.id] as String,
          label: label,
        ),
      );
    }

    return options;
  }

  Future<List<TripRouteLookupOptionModel>> _getRouteLookupOptions({
    required String companyId,
  }) async {
    final rows = await client
        .from(TripLookupDbFields.routesTableName)
        .select(TripLookupDbFields.routeColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(TripLookupDbFields.loadingLocation);

    final options = <TripRouteLookupOptionModel>[];

    for (final row in rows) {
      final model = TripRouteLookupOptionModel.fromMap(
        Map<String, dynamic>.from(row),
      );
      if (model.label == ' -> ') continue;
      options.add(model);
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
          .from(TripDbFields.tableName)
          .select(DbCommonFields.id)
          .eq(DbCommonFields.companyId, companyId)
          .eq(column, vehicleId)
          .or(TripDbFields.openTripStatusFilter)
          .limit(1);

      return rows.isNotEmpty;
    }

    final rows = await client
        .from(TripDbFields.tableName)
        .select(DbCommonFields.id)
        .eq(DbCommonFields.companyId, companyId)
        .eq(column, vehicleId)
        .neq(DbCommonFields.id, excludingTripId)
        .or(TripDbFields.openTripStatusFilter)
        .limit(1);

    return rows.isNotEmpty;
  }

  Future<String?> _getCurrentActorDisplayName() async {
    final currentUser = client.auth.currentUser;
    final currentUserId = currentUser?.id;
    final currentUserEmail = currentUser?.email;
    if (currentUserId == null) return null;

    final rows = await client
        .from(UserProfileDbFields.tableName)
        .select(UserProfileDbFields.fullName)
        .eq(DbCommonFields.id, currentUserId)
        .limit(1);

    if (rows.isNotEmpty) {
      final firstRow = Map<String, dynamic>.from(rows.first);
      final fullName = _normalizeOptional(
        firstRow[UserProfileDbFields.fullName] as String?,
      );
      if (fullName != null) return fullName;
    }

    return _normalizeOptional(currentUserEmail);
  }

  String? _normalizeOptional(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}
