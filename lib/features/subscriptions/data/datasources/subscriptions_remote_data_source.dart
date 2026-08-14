import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../constants/subscriptions_db_fields.dart';
import '../models/company_subscription_model.dart';
import '../models/subscription_plan_model.dart';

abstract interface class SubscriptionsRemoteDataSource {
  Future<List<SubscriptionPlanModel>> getAvailablePlans();

  Future<CompanySubscriptionModel?> getCurrentCompanySubscription({
    required String companyId,
  });
}

final class SupabaseSubscriptionsRemoteDataSource
    implements SubscriptionsRemoteDataSource {
  final SupabaseClient _client;

  const SupabaseSubscriptionsRemoteDataSource(this._client);

  @override
  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    final response = await _client
        .from(SubscriptionsDbFields.subscriptionPlansTable)
        .select(SubscriptionsDbFields.planColumns)
        .eq(DbCommonFields.isActive, true)
        .order(SubscriptionsDbFields.monthlyPrice)
        .order(SubscriptionsDbFields.code);

    return response
        .map(
          (item) =>
              SubscriptionPlanModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<CompanySubscriptionModel?> getCurrentCompanySubscription({
    required String companyId,
  }) async {
    final response = await _client
        .from(SubscriptionsDbFields.companySubscriptionsTable)
        .select(SubscriptionsDbFields.companySubscriptionColumns)
        .eq(DbCommonFields.companyId, companyId)
        .maybeSingle();

    if (response == null) return null;
    return CompanySubscriptionModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }
}
