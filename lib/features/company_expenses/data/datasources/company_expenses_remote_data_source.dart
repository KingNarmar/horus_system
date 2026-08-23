import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/company_expense_void_data.dart';
import '../../domain/entities/company_expense_write_data.dart';
import '../constants/company_expense_db_fields.dart';
import '../mappers/company_expense_mapper.dart';
import '../models/company_expense_category_model.dart';
import '../models/company_expense_form_lookups_model.dart';
import '../models/company_expense_link_option_model.dart';
import '../models/company_expense_model.dart';

abstract class CompanyExpensesRemoteDataSource {
  Future<List<CompanyExpenseCategoryModel>> getCategories({
    required String companyId,
    required bool includeInactive,
  });

  Future<List<CompanyExpenseModel>> getCompanyExpenses({
    required String companyId,
    required bool includeVoided,
  });

  Future<CompanyExpenseFormLookupsModel> getFormLookups({
    required String companyId,
  });

  Future<CompanyExpenseModel> getCompanyExpenseById({
    required String companyId,
    required String id,
  });

  Future<CompanyExpenseModel> addCompanyExpense({
    required CompanyExpenseWriteData data,
  });

  Future<CompanyExpenseModel> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
  });

  Future<CompanyExpenseModel> voidCompanyExpense({
    required CompanyExpenseVoidData data,
  });
}

class SupabaseCompanyExpensesRemoteDataSource
    implements CompanyExpensesRemoteDataSource {
  final SupabaseClient client;

  const SupabaseCompanyExpensesRemoteDataSource(this.client);

  @override
  Future<List<CompanyExpenseCategoryModel>> getCategories({
    required String companyId,
    required bool includeInactive,
  }) async {
    var query = client
        .from(CompanyExpenseCategoryDbFields.tableName)
        .select(CompanyExpenseCategoryDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId);

    if (!includeInactive) {
      query = query.eq(DbCommonFields.isActive, true);
    }

    final rows = await query.order(CompanyExpenseCategoryDbFields.name);
    return rows
        .map(
          (row) => CompanyExpenseCategoryModel.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  @override
  Future<List<CompanyExpenseModel>> getCompanyExpenses({
    required String companyId,
    required bool includeVoided,
  }) async {
    var query = client
        .from(CompanyExpenseDbFields.tableName)
        .select(CompanyExpenseDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId);

    if (!includeVoided) {
      query = query.eq(CompanyExpenseDbFields.isVoided, false);
    }

    final rows = await query
        .order(CompanyExpenseDbFields.expenseDate, ascending: false)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map(
          (row) => CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  @override
  Future<CompanyExpenseFormLookupsModel> getFormLookups({
    required String companyId,
  }) async {
    final results = await Future.wait<List<CompanyExpenseLinkOptionModel>>([
      _getActiveLookupOptions(
        tableName: CompanyExpenseLookupDbFields.driversTableName,
        companyId: companyId,
        labelFields: const [CompanyExpenseLookupDbFields.fullName],
        orderColumn: CompanyExpenseLookupDbFields.fullName,
      ),
      _getActiveLookupOptions(
        tableName: CompanyExpenseLookupDbFields.tractorHeadsTableName,
        companyId: companyId,
        labelFields: const [CompanyExpenseLookupDbFields.plateNumber],
        orderColumn: CompanyExpenseLookupDbFields.plateNumber,
      ),
      _getActiveLookupOptions(
        tableName: CompanyExpenseLookupDbFields.trailersTableName,
        companyId: companyId,
        labelFields: const [CompanyExpenseLookupDbFields.plateNumber],
        orderColumn: CompanyExpenseLookupDbFields.plateNumber,
      ),
      _getTripLookupOptions(companyId: companyId),
    ]);

    return CompanyExpenseFormLookupsModel(
      drivers: results[0],
      tractorHeads: results[1],
      trailers: results[2],
      trips: results[3],
    );
  }

  @override
  Future<CompanyExpenseModel> getCompanyExpenseById({
    required String companyId,
    required String id,
  }) async {
    final row = await client
        .from(CompanyExpenseDbFields.tableName)
        .select(CompanyExpenseDbFields.allColumns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.id, id)
        .single();

    return CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<CompanyExpenseModel> addCompanyExpense({
    required CompanyExpenseWriteData data,
  }) async {
    final row = await client
        .from(CompanyExpenseDbFields.tableName)
        .insert(data.toInsertMap())
        .select(CompanyExpenseDbFields.allColumns)
        .single();

    return CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<CompanyExpenseModel> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
  }) async {
    final updateMap = data.toUpdateMap();
    final actorUserId = client.auth.currentUser?.id;
    if (actorUserId != null) {
      updateMap[DbCommonFields.updatedBy] = actorUserId;
    }

    final row = await client
        .from(CompanyExpenseDbFields.tableName)
        .update(updateMap)
        .eq(DbCommonFields.companyId, data.companyId)
        .eq(DbCommonFields.id, id)
        .select(CompanyExpenseDbFields.allColumns)
        .single();

    return CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<CompanyExpenseModel> voidCompanyExpense({
    required CompanyExpenseVoidData data,
  }) async {
    final actorUserId = client.auth.currentUser?.id;
    final row = await client
        .from(CompanyExpenseDbFields.tableName)
        .update(data.toVoidMap(actorUserId: actorUserId))
        .eq(DbCommonFields.companyId, data.companyId)
        .eq(DbCommonFields.id, data.expenseId)
        .select(CompanyExpenseDbFields.allColumns)
        .single();

    return CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<CompanyExpenseLinkOptionModel>> _getActiveLookupOptions({
    required String tableName,
    required String companyId,
    required List<String> labelFields,
    required String orderColumn,
  }) async {
    final columns = [DbCommonFields.id, ...labelFields].join(', ');
    final rows = await client
        .from(tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(orderColumn);

    return rows
        .map(
          (row) => _lookupOptionFromRow(
            Map<String, dynamic>.from(row),
            labelFields: labelFields,
          ),
        )
        .toList();
  }

  Future<List<CompanyExpenseLinkOptionModel>> _getTripLookupOptions({
    required String companyId,
  }) async {
    final rows = await client
        .from(CompanyExpenseLookupDbFields.tripsTableName)
        .select(CompanyExpenseLookupDbFields.tripColumns)
        .eq(DbCommonFields.companyId, companyId)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map(
          (row) => _lookupOptionFromRow(
            Map<String, dynamic>.from(row),
            labelFields: const [
              CompanyExpenseLookupDbFields.loadingOrderNumber,
              CompanyExpenseLookupDbFields.waybillNumber,
            ],
          ),
        )
        .toList();
  }

  CompanyExpenseLinkOptionModel _lookupOptionFromRow(
    Map<String, dynamic> row, {
    required List<String> labelFields,
  }) {
    final id = row[DbCommonFields.id] as String;
    return CompanyExpenseLinkOptionModel(
      id: id,
      label: _firstText(row, labelFields) ?? id,
    );
  }

  String? _firstText(Map<String, dynamic> row, List<String> fields) {
    for (final field in fields) {
      final text = row[field]?.toString().trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
