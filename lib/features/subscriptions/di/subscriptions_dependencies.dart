import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/company_entitlements_remote_data_source.dart';
import '../data/datasources/subscriptions_remote_data_source.dart';
import '../data/repositories/company_entitlements_repository_impl.dart';
import '../data/repositories/subscriptions_repository_impl.dart';
import '../domain/repositories/company_entitlements_repository.dart';
import '../domain/repositories/subscriptions_repository.dart';
import '../domain/usecases/get_company_entitlement_usecase.dart';
import '../domain/usecases/get_available_subscription_plans_usecase.dart';
import '../domain/usecases/get_current_company_subscription_usecase.dart';
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

  static SubscriptionsRepository createRepository() {
    return SubscriptionsRepositoryImpl(
      remoteDataSource: SupabaseSubscriptionsRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static SubscriptionsCubit createCubit() {
    final repository = createRepository();
    return SubscriptionsCubit(
      getAvailablePlansUseCase: GetAvailableSubscriptionPlansUseCase(
        repository,
      ),
      getCurrentSubscriptionUseCase: GetCurrentCompanySubscriptionUseCase(
        repository,
      ),
    );
  }
}
