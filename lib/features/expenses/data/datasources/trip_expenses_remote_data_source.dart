import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/expense_type_option.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../constants/trip_expense_db_fields.dart';
import '../mappers/trip_expense_mapper.dart';
import '../models/trip_expense_model.dart';

abstract class TripExpensesRemoteDataSource {
  Future<List<TripExpenseModel>> getTripExpenses({
    required String companyId,
    required String tripId,
  });

  Future<List<ExpenseTypeOption>> getExpenseTypes({required String companyId});

  Future<TripExpenseModel> addTripExpense({required TripExpenseWriteData data});

  Future<TripExpenseModel> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
  });

  Future<double> getTripTotalExpenses({
    required String companyId,
    required String tripId,
  });
}

class SupabaseTripExpensesRemoteDataSource
    implements TripExpensesRemoteDataSource {
  final SupabaseClient client;

  const SupabaseTripExpensesRemoteDataSource(this.client);

  @override
  Future<List<TripExpenseModel>> getTripExpenses({
    required String companyId,
    required String tripId,
  }) async {
    final rows = await client
        .from(TripExpenseDbFields.tableName)
        .select(TripExpenseDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(TripExpenseDbFields.tripId, tripId)
        .order(TripExpenseDbFields.expenseDate, ascending: false)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map((row) => TripExpenseModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<List<ExpenseTypeOption>> getExpenseTypes({
    required String companyId,
  }) async {
    final rows = await client
        .from(TripExpenseTypeLookupDbFields.tableName)
        .select(TripExpenseTypeLookupDbFields.lookupColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(TripExpenseTypeLookupDbFields.name);

    final options = <ExpenseTypeOption>[];

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final name =
          map[TripExpenseTypeLookupDbFields.name]?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      options.add(
        ExpenseTypeOption(id: map[DbCommonFields.id] as String, name: name),
      );
    }

    return options;
  }

  @override
  Future<TripExpenseModel> addTripExpense({
    required TripExpenseWriteData data,
  }) async {
    final row = await client
        .from(TripExpenseDbFields.tableName)
        .insert(data.toInsertMap())
        .select(TripExpenseDbFields.allColumns)
        .single();

    return TripExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripExpenseModel> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
  }) async {
    final row = await client
        .from(TripExpenseDbFields.tableName)
        .update(data.toUpdateMap())
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(TripExpenseDbFields.allColumns)
        .single();

    return TripExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<double> getTripTotalExpenses({
    required String companyId,
    required String tripId,
  }) async {
    final row = await client
        .from(TripExpenseLinkedTripDbFields.tableName)
        .select(TripExpenseLinkedTripDbFields.totalExpenses)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.id, tripId)
        .single();

    final total = Map<String, dynamic>.from(
      row,
    )[TripExpenseLinkedTripDbFields.totalExpenses];
    if (total is num) return total.toDouble();
    return double.tryParse(total.toString()) ?? 0;
  }
}
