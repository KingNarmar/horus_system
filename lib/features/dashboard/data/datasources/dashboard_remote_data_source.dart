import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/dashboard_db_constants.dart';
import '../models/dashboard_source_model.dart';

abstract interface class DashboardRemoteDataSource {
  Future<DashboardSourceModel> getDashboardSource({required String companyId});
}

final class SupabaseDashboardRemoteDataSource
    implements DashboardRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseDashboardRemoteDataSource(this._client);

  @override
  Future<DashboardSourceModel> getDashboardSource({
    required String companyId,
  }) async {
    final response = await _client.rpc(
      DashboardDbConstants.getDashboardSourceRpc,
      params: {DashboardDbConstants.companyIdParam: companyId},
    );

    return DashboardSourceModel.fromMap(_singleMap(response));
  }
}

Map<String, dynamic> _singleMap(Object? response) {
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }
  if (response is List && response.length == 1 && response.single is Map) {
    return Map<String, dynamic>.from(response.single as Map);
  }
  throw const FormatException('Invalid dashboard RPC response.');
}
