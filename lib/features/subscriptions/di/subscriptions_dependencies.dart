import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/company_entitlements_remote_data_source.dart';
import '../data/datasources/company_quota_remote_data_source.dart';
import '../data/datasources/subscriptions_remote_data_source.dart';
import '../data/repositories/company_entitlements_repository_impl.dart';
import '../data/repositories/company_quota_repository_impl.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/company_entitlements_repository.dart';
import '../domain/repositories/company_quota_repository.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/get_company_entitlement_usecase.dart';
import '../domain/usecases/get_company_quota_usage_usecase.dart';
import '../presentation/cubit/subscriptions_cubit.dart';

abstract final class SubscriptionsDependencies {
  static CompanyEntitlementsRepository createEntitlementRepository() {
    return CompanyEntitlementsRepositoryImpl(
      SupabaseCompanyEntitlementsRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static GetCompanyEntitlementUseCase createEntitlementUseCase() {
    return GetCompanyEntitlementUseCase(createEntitlementRepository());
  }

  static CompanyQuotaRepository createQuotaRepository() {
    return CompanyQuotaRepositoryImpl(
      SupabaseCompanyQuotaRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static GetCompanyQuotaUsageUseCase createQuotaUseCase() {
    return GetCompanyQuotaUsageUseCase(createQuotaRepository());
  }

  static SubscriptionsRepository createRepository() {
    return SubscriptionsRepositoryImpl(
      remoteDataSource: SupabaseSubscriptionsRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static SubscriptionsCubit createCubit() {
    return SubscriptionsCubit(
      getCompanyQuotaUsageUseCase: createQuotaUseCase(),
    );
  }
}
