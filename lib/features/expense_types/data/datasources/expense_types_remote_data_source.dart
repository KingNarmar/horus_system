import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/expense_type_write_data.dart';
import '../constants/expense_type_db_fields.dart';
import '../mappers/expense_type_mapper.dart';
import '../models/expense_type_model.dart';

abstract interface class ExpenseTypesRemoteDataSource {
  Future<List<ExpenseTypeModel>> getExpenseTypes({required String companyId});

  Future<List<ExpenseTypeModel>> getActiveExpenseTypes({
    required String companyId,
  });

  Future<ExpenseTypeModel> getExpenseTypeById({
    required String companyId,
    required String expenseTypeId,
  });

  Future<ExpenseTypeModel> addExpenseType({required ExpenseTypeWriteData data});

  Future<ExpenseTypeModel> updateExpenseType({
    required String expenseTypeId,
    required ExpenseTypeWriteData data,
  });

  Future<ExpenseTypeModel> deactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
  });

  Future<ExpenseTypeModel> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
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
  Future<ExpenseTypeModel> getExpenseTypeById({
    required String companyId,
    required String expenseTypeId,
  }) async {
    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.id, expenseTypeId)
        .eq(DbCommonFields.companyId, companyId)
        .single();
    return ExpenseTypeModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<ExpenseTypeModel> addExpenseType({
    required ExpenseTypeWriteData data,
  }) async {
    final values = data.toInsertMap();
    final actorUserId = client.auth.currentUser?.id;
    if (actorUserId != null) {
      values[DbCommonFields.createdBy] = actorUserId;
    }

    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .insert(values)
        .select(columns)
        .single();
    return ExpenseTypeModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<ExpenseTypeModel> updateExpenseType({
    required String expenseTypeId,
    required ExpenseTypeWriteData data,
  }) async {
    final values = data.toUpdateMap();
    _addUpdatedBy(values);
    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .update(values)
        .eq(DbCommonFields.id, expenseTypeId)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(columns)
        .single();
    return ExpenseTypeModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<ExpenseTypeModel> deactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
  }) {
    return _setActive(
      companyId: companyId,
      expenseTypeId: expenseTypeId,
      isActive: false,
    );
  }

  @override
  Future<ExpenseTypeModel> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
  }) {
    return _setActive(
      companyId: companyId,
      expenseTypeId: expenseTypeId,
      isActive: true,
    );
  }

  Future<ExpenseTypeModel> _setActive({
    required String companyId,
    required String expenseTypeId,
    required bool isActive,
  }) async {
    final values = <String, dynamic>{DbCommonFields.isActive: isActive};
    _addUpdatedBy(values);
    final response = await client
        .from(ExpenseTypeDbFields.tableName)
        .update(values)
        .eq(DbCommonFields.id, expenseTypeId)
        .eq(DbCommonFields.companyId, companyId)
        .select(columns)
        .single();
    return ExpenseTypeModel.fromMap(Map<String, dynamic>.from(response));
  }

  void _addUpdatedBy(Map<String, dynamic> values) {
    final actorUserId = client.auth.currentUser?.id;
    if (actorUserId != null) {
      values[DbCommonFields.updatedBy] = actorUserId;
    }
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
