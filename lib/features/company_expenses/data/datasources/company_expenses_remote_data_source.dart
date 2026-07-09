import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/company_expense_void_data.dart';
import '../../domain/entities/company_expense_write_data.dart';
import '../mappers/company_expense_mapper.dart';
import '../models/company_expense_category_model.dart';
import '../models/company_expense_form_lookups_model.dart';
import '../models/company_expense_link_option_model.dart';
import '../models/company_expense_model.dart';

const _companyExpenseCategoriesTable = 'company_expense_categories';
const _companyExpensesTable = 'company_expenses';
const _driversTable = 'drivers';
const _tractorHeadsTable = 'tractor_heads';
const _trailersTable = 'trailers';
const _tripsTable = 'trips';

const _companyExpenseCategoryColumns = '''
id,
company_id,
name,
code,
is_active,
created_at,
updated_at
''';

const _companyExpenseColumns = '''
id,
company_id,
category_id,
driver_id,
tractor_head_id,
trailer_id,
trip_id,
amount,
expense_date,
reference_number,
notes,
is_voided,
voided_at,
voided_by,
void_reason,
created_at,
updated_at
''';

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
        .from(_companyExpenseCategoriesTable)
        .select(_companyExpenseCategoryColumns)
        .eq(DbCommonFields.companyId, companyId);

    if (!includeInactive) {
      query = query.eq(DbCommonFields.isActive, true);
    }

    final rows = await query.order('name');
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
        .from(_companyExpensesTable)
        .select(_companyExpenseColumns)
        .eq(DbCommonFields.companyId, companyId);

    if (!includeVoided) {
      query = query.eq('is_voided', false);
    }

    final rows = await query
        .order('expense_date', ascending: false)
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
    final results = await Future.wait([
      _getActiveLookupOptions(
        tableName: _driversTable,
        companyId: companyId,
        labelFields: const ['full_name'],
        orderColumn: 'full_name',
      ),
      _getActiveLookupOptions(
        tableName: _tractorHeadsTable,
        companyId: companyId,
        labelFields: const ['plate_number'],
        orderColumn: 'plate_number',
      ),
      _getActiveLookupOptions(
        tableName: _trailersTable,
        companyId: companyId,
        labelFields: const ['plate_number'],
        orderColumn: 'plate_number',
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
        .from(_companyExpensesTable)
        .select(_companyExpenseColumns)
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
        .from(_companyExpensesTable)
        .insert(data.toInsertMap())
        .select(_companyExpenseColumns)
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
      updateMap['updated_by'] = actorUserId;
    }

    final row = await client
        .from(_companyExpensesTable)
        .update(updateMap)
        .eq(DbCommonFields.companyId, data.companyId)
        .eq(DbCommonFields.id, id)
        .select(_companyExpenseColumns)
        .single();

    return CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<CompanyExpenseModel> voidCompanyExpense({
    required CompanyExpenseVoidData data,
  }) async {
    final actorUserId = client.auth.currentUser?.id;
    final row = await client
        .from(_companyExpensesTable)
        .update(data.toVoidMap(actorUserId: actorUserId))
        .eq(DbCommonFields.companyId, data.companyId)
        .eq(DbCommonFields.id, data.expenseId)
        .select(_companyExpenseColumns)
        .single();

    return CompanyExpenseModel.fromMap(Map<String, dynamic>.from(row));
  }

  Future<List<CompanyExpenseLinkOptionModel>> _getActiveLookupOptions({
    required String tableName,
    required String companyId,
    required List<String> labelFields,
    required String orderColumn,
  }) async {
    final columns = ['id', ...labelFields].join(', ');
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
        .from(_tripsTable)
        .select('id, loading_order_number, waybill_number, created_at')
        .eq(DbCommonFields.companyId, companyId)
        .order(DbCommonFields.createdAt, ascending: false);

    return rows
        .map(
          (row) => _lookupOptionFromRow(
            Map<String, dynamic>.from(row),
            labelFields: const ['loading_order_number', 'waybill_number'],
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
