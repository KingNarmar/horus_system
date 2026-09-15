import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/expense_type_db_fields.dart';
import '../models/expense_type_model.dart';

abstract interface class ExpenseTypesRemoteDataSource {
  Future<List<ExpenseTypeModel>> getExpenseTypes({required String companyId});

  Future<List<ExpenseTypeModel>> getActiveExpenseTypes({
    required String companyId,
  });

  Future<List<ExpenseTypeModel>> getLedgerEligibleExpenseTypes({
    required String companyId,
  });
}

class SupabaseExpenseTypesRemoteDataSource
    implements ExpenseTypesRemoteDataSource {
  static const String columns = ExpenseTypeDbFields.allColumns;

  final SupabaseClient client;

  const SupabaseExpenseTypesRemoteDataSource(this.client);

  @override
  Future<List<ExpenseTypeModel>> getExpenseTypes({
    required String companyId,
  }) async {
    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .order(ExpenseTypeDbFields.name);
    return _modelsFromResponse(response);
  }

  @override
  Future<List<ExpenseTypeModel>> getActiveExpenseTypes({
    required String companyId,
  }) async {
    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(ExpenseTypeDbFields.name);
    return _modelsFromResponse(response);
  }

  @override
  Future<List<ExpenseTypeModel>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) async {
    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .eq(ExpenseTypeDbFields.ledgerEligible, true)
        .order(ExpenseTypeDbFields.name);
    return _modelsFromResponse(response);
  }

  List<ExpenseTypeModel> _modelsFromResponse(
    List<Map<String, dynamic>> response,
  ) {
    return response
        .map(
          (item) => ExpenseTypeModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
