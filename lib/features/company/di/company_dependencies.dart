import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../../core/domain/services/company_business_date_provider.dart';
import '../data/datasources/company_business_date_remote_data_source.dart';
import '../data/datasources/company_regional_settings_remote_data_source.dart';
import '../data/repositories/company_regional_settings_repository_impl.dart';
import '../data/services/company_business_date_provider_impl.dart';
import '../domain/repositories/company_regional_settings_repository.dart';
import '../domain/usecases/update_company_regional_settings_usecase.dart';

abstract final class CompanyDependencies {
  static CompanyRegionalSettingsRepository createRegionalSettingsRepository() {
    return CompanyRegionalSettingsRepositoryImpl(
      SupabaseCompanyRegionalSettingsRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static CompanyBusinessDateProvider createBusinessDateProvider() {
    return CompanyBusinessDateProviderImpl(
      SupabaseCompanyBusinessDateRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static UpdateCompanyRegionalSettingsUseCase
  createUpdateRegionalSettingsUseCase() {
    return UpdateCompanyRegionalSettingsUseCase(
      createRegionalSettingsRepository(),
    );
  }
}
