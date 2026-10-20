import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/authorized_business_records_db_contract.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../domain/entities/trip_status.dart';
import '../../domain/entities/trip_write_data.dart';
import '../constants/trip_db_contract.dart';
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
    required DateTime expectedUpdatedAt,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<TripModel> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
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
    final result = await client.rpc(
      AuthorizedBusinessRecordsDbRpcs.trips,
      params: {AuthorizedBusinessRecordsDbParams.companyId: companyId},
    );
    return _rpcRows(result).map(TripModel.fromMap).toList();
  }

  @override
  Future<TripModel> getTripById({
    required String companyId,
    required String id,
  }) async {
    final result = await client.rpc(
      AuthorizedBusinessRecordsDbRpcs.trips,
      params: {
        AuthorizedBusinessRecordsDbParams.companyId: companyId,
        AuthorizedBusinessRecordsDbParams.tripId: id,
      },
    );
    final records = _rpcRows(result);
    if (records.isEmpty) {
      throw const PostgrestException(
        message: 'trip_not_found',
        code: TripDbErrorCodes.notFound,
      );
    }
    if (records.length != 1) {
      throw const FormatException('Duplicate Trip records.');
    }
    return TripModel.fromMap(records.single);
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
    final result = await client.rpc(
      TripDbRpcs.create,
      params: data.toMutationRpcParams(
        financialConfiguration: financialConfiguration,
      ),
    );

    return TripModel.fromMap(_rpcMap(result));
  }

  @override
  Future<TripModel> saveTrip({
    required String id,
    required DateTime expectedUpdatedAt,
    required TripWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  }) async {
    final params =
        data.toMutationRpcParams(financialConfiguration: financialConfiguration)
          ..[TripDbRpcParams.tripId] = id
          ..[TripDbRpcParams.expectedUpdatedAt] = expectedUpdatedAt
              .toUtc()
              .toIso8601String();

    final result = await client.rpc(TripDbRpcs.saveChecked, params: params);
    return TripModel.fromMap(_rpcMap(result));
  }

  @override
  Future<TripModel> updateTripStatus({
    required String companyId,
    required String id,
    required TripStatus newStatus,
    String? notes,
  }) async {
    final result = await client.rpc(
      TripDbRpcs.updateStatus,
      params: {
        TripDbRpcParams.companyId: companyId,
        TripDbRpcParams.tripId: id,
        TripDbRpcParams.newStatus: newStatus.value,
        TripDbRpcParams.notes: notes,
      },
    );

    return TripModel.fromMap(_rpcMap(result));
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
    final result = await client.rpc(
      AuthorizedBusinessRecordsDbRpcs.routes,
      params: {
        AuthorizedBusinessRecordsDbParams.companyId: companyId,
        AuthorizedBusinessRecordsDbParams.activeOnly: true,
      },
    );
    final rows = _rpcRows(result);

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

  List<Map<String, dynamic>> _rpcRows(Object? value) {
    if (value is! List) {
      throw const FormatException('Invalid Trip read response.');
    }
    return value.map(_rpcMap).toList(growable: false);
  }

  Map<String, dynamic> _rpcMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Invalid trip RPC response.');
  }
}
