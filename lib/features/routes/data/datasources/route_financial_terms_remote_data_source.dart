import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/route_db_contract.dart';
import '../models/route_model.dart';

abstract class RouteFinancialTermsRemoteDataSource {
  Future<RouteModel> setDefaultFreightRate({
    required String companyId,
    required String routeId,
    required String rateDecimal,
    required DateTime expectedUpdatedAt,
  });
}

final class SupabaseRouteFinancialTermsRemoteDataSource
    implements RouteFinancialTermsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseRouteFinancialTermsRemoteDataSource(this._client);

  @override
  Future<RouteModel> setDefaultFreightRate({
    required String companyId,
    required String routeId,
    required String rateDecimal,
    required DateTime expectedUpdatedAt,
  }) async {
    final result = await _client.rpc(
      RouteFinancialDbRpcs.setDefaultFreightRate,
      params: {
        RouteFinancialDbRpcParams.companyId: companyId,
        RouteFinancialDbRpcParams.routeId: routeId,
        RouteFinancialDbRpcParams.rate: rateDecimal,
        RouteFinancialDbRpcParams.expectedUpdatedAt: expectedUpdatedAt
            .toUtc()
            .toIso8601String(),
      },
    );
    if (result is! Map) {
      throw const FormatException('Invalid Route financial update response.');
    }
    return RouteModel.fromMap(Map<String, dynamic>.from(result));
  }
}
