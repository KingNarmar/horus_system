import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/customer_statements_db_constants.dart';
import '../models/customer_statement_source_model.dart';

abstract interface class CustomerStatementsRemoteDataSource {
  Future<CustomerStatementSourceModel> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  });
}

final class SupabaseCustomerStatementsRemoteDataSource
    implements CustomerStatementsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseCustomerStatementsRemoteDataSource(this._client);

  @override
  Future<CustomerStatementSourceModel> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await _client.rpc(
      CustomerStatementsDbConstants.getStatementSourceRpc,
      params: {
        CustomerStatementsDbConstants.companyIdParam: companyId,
        CustomerStatementsDbConstants.customerIdParam: customerId,
        CustomerStatementsDbConstants.fromDateParam: _dateValue(fromDate),
        CustomerStatementsDbConstants.toDateParam: _dateValue(toDate),
      },
    );

    return CustomerStatementSourceModel.fromMap(_singleMap(response));
  }
}

Map<String, dynamic> _singleMap(Object? response) {
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }
  if (response is List && response.length == 1 && response.single is Map) {
    return Map<String, dynamic>.from(response.single as Map);
  }
  throw const FormatException('Invalid customer statement RPC response.');
}

String? _dateValue(DateTime? value) {
  if (value == null) return null;
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
