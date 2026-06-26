import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../../domain/entities/expense_type_option.dart';
import '../../domain/entities/trip_expense_write_data.dart';
import '../mappers/trip_expense_mapper.dart';
import '../models/trip_expense_model.dart';

const _tripExpensesTable = 'trip_expenses';
const _expenseTypesTable = 'expense_types';
const _tripsTable = 'trips';

const _tripExpenseColumns = '''
id,
company_id,
trip_id,
expense_type_id,
expense_name,
amount,
paid_by,
expense_date,
notes,
created_at,
updated_at,
expense_types!trip_expenses_company_type_fk(name)
''';

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

  Future<double> recalculateTripTotalExpenses({
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
        .from(_tripExpensesTable)
        .select(_tripExpenseColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq('trip_id', tripId)
        .order('expense_date', ascending: false)
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
        .from(_expenseTypesTable)
        .select('id, name')
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order('name');

    final options = <ExpenseTypeOption>[];

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final name = map['name']?.toString().trim() ?? '';
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
        .from(_tripExpensesTable)
        .insert(data.toInsertMap())
        .select(_tripExpenseColumns)
        .single();

    return TripExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<TripExpenseModel> updateTripExpense({
    required String id,
    required TripExpenseWriteData data,
  }) async {
    final row = await client
        .from(_tripExpensesTable)
        .update(data.toUpdateMap())
        .eq(DbCommonFields.id, id)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(_tripExpenseColumns)
        .single();

    return TripExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<double> recalculateTripTotalExpenses({
    required String companyId,
    required String tripId,
  }) async {
    final rows = await client
        .from(_tripExpensesTable)
        .select('amount')
        .eq(DbCommonFields.companyId, companyId)
        .eq('trip_id', tripId);

    var total = 0.0;
    for (final row in rows) {
      final amount = Map<String, dynamic>.from(row)['amount'];
      if (amount is num) {
        total += amount.toDouble();
      } else {
        total += double.tryParse(amount.toString()) ?? 0;
      }
    }

    await client
        .from(_tripsTable)
        .update({
          'total_expenses': total,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.id, tripId);

    return total;
  }
}
