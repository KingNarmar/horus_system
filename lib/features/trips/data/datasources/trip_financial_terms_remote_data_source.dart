import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/trip_db_contract.dart';
import '../models/trip_model.dart';

abstract class TripFinancialTermsRemoteDataSource {
  Future<TripModel> setFreightRate({
    required String companyId,
    required String tripId,
    required String rateDecimal,
    required DateTime expectedUpdatedAt,
  });
}

final class SupabaseTripFinancialTermsRemoteDataSource
    implements TripFinancialTermsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseTripFinancialTermsRemoteDataSource(this._client);

  @override
  Future<TripModel> setFreightRate({
    required String companyId,
    required String tripId,
    required String rateDecimal,
    required DateTime expectedUpdatedAt,
  }) async {
    final result = await _client.rpc(
      TripDbRpcs.setFreightRate,
      params: {
        TripDbRpcParams.companyId: companyId,
        TripDbRpcParams.tripId: tripId,
        TripDbRpcParams.agreedFreightRatePerTon: rateDecimal,
        TripDbRpcParams.expectedUpdatedAt:
            expectedUpdatedAt.toUtc().toIso8601String(),
      },
    );

    if (result is! Map) {
      throw const FormatException('Invalid Trip financial update response.');
    }
    return TripModel.fromMap(Map<String, dynamic>.from(result));
  }
}
