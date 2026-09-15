import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/expense_ledger_write_data.dart';
import '../constants/expense_ledger_db_fields.dart';
import '../constants/expense_ledger_rpc_constants.dart';
import '../mappers/expense_ledger_mapper.dart';
import '../models/expense_ledger_entry_model.dart';

abstract class ExpenseLedgerRemoteDataSource {
  Future<List<ExpenseLedgerEntryModel>> getEntries({
    required String companyId,
    required bool includeVoided,
  });

  Future<List<ExpenseLedgerEntryModel>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    required bool includeVoided,
  });

  Future<ExpenseLedgerEntryModel> createEntry(ExpenseLedgerWriteData data);

  Future<ExpenseLedgerEntryModel> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  });
}

final class SupabaseExpenseLedgerRemoteDataSource
    implements ExpenseLedgerRemoteDataSource {
  final SupabaseClient client;

  const SupabaseExpenseLedgerRemoteDataSource(this.client);

  @override
  Future<List<ExpenseLedgerEntryModel>> getEntries({
    required String companyId,
    required bool includeVoided,
  }) async {
    final baseQuery = client
        .from(ExpenseLedgerDbFields.tableName)
        .select(ExpenseLedgerDbFields.allColumns)
        .eq(ExpenseLedgerDbFields.companyId, companyId);

    final List<dynamic> response;
    if (includeVoided) {
      response = await baseQuery
          .order(ExpenseLedgerDbFields.expenseDate, ascending: false)
          .order(ExpenseLedgerDbFields.createdAt, ascending: false);
    } else {
      response = await baseQuery
          .eq(ExpenseLedgerDbFields.isVoided, false)
          .order(ExpenseLedgerDbFields.expenseDate, ascending: false)
          .order(ExpenseLedgerDbFields.createdAt, ascending: false);
    }

    return _modelsFromResponse(response);
  }

  @override
  Future<List<ExpenseLedgerEntryModel>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    required bool includeVoided,
  }) async {
    final baseQuery = client
        .from(ExpenseLedgerDbFields.tableName)
        .select(ExpenseLedgerDbFields.allColumns)
        .eq(ExpenseLedgerDbFields.companyId, companyId)
        .eq(ExpenseLedgerDbFields.tripId, tripId);

    final List<dynamic> response;
    if (includeVoided) {
      response = await baseQuery
          .order(ExpenseLedgerDbFields.expenseDate, ascending: false)
          .order(ExpenseLedgerDbFields.createdAt, ascending: false);
    } else {
      response = await baseQuery
          .eq(ExpenseLedgerDbFields.isVoided, false)
          .order(ExpenseLedgerDbFields.expenseDate, ascending: false)
          .order(ExpenseLedgerDbFields.createdAt, ascending: false);
    }

    return _modelsFromResponse(response);
  }

  @override
  Future<ExpenseLedgerEntryModel> createEntry(
    ExpenseLedgerWriteData data,
  ) async {
    final response = await client.rpc(
      ExpenseLedgerRpcConstants.create,
      params: data.toCreateRpcParams(),
    );
    return ExpenseLedgerEntryModel.fromMap(_singleRow(response));
  }

  @override
  Future<ExpenseLedgerEntryModel> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) async {
    final response = await client.rpc(
      ExpenseLedgerRpcConstants.voidEntry,
      params: {
        ExpenseLedgerRpcConstants.companyId: companyId,
        ExpenseLedgerRpcConstants.expenseId: expenseId,
        ExpenseLedgerRpcConstants.reason: reason,
      },
    );
    return ExpenseLedgerEntryModel.fromMap(_singleRow(response));
  }

  List<ExpenseLedgerEntryModel> _modelsFromResponse(List<dynamic> response) {
    return response
        .map(
          (row) => ExpenseLedgerEntryModel.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _singleRow(Object? response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    if (response is List && response.length == 1 && response.first is Map) {
      return Map<String, dynamic>.from(response.first as Map);
    }
    throw const FormatException('Expected one expense ledger row.');
  }
}
