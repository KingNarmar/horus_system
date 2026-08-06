import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../company/di/company_dependencies.dart';
import '../data/datasources/invoice_settings_remote_data_source.dart';
import '../data/datasources/invoices_remote_data_source.dart';
import '../data/repositories/invoice_settings_repository_impl.dart';
import '../data/repositories/invoices_repository_impl.dart';
import '../domain/repositories/invoice_settings_repository.dart';
import '../domain/repositories/invoices_repository.dart';
import '../domain/usecases/invoice_draft_usecases.dart';
import '../domain/usecases/invoice_lifecycle_usecases.dart';
import '../domain/usecases/invoice_query_usecases.dart';
import '../domain/usecases/invoice_settings_usecases.dart';
import '../presentation/cubit/invoices_cubit.dart';

abstract final class InvoicesDependencies {
  static InvoicesRepository createRepository() {
    return InvoicesRepositoryImpl(
      SupabaseInvoicesRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static InvoiceSettingsRepository createSettingsRepository() {
    return InvoiceSettingsRepositoryImpl(
      SupabaseInvoiceSettingsRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static GetInvoicesUseCase createGetInvoicesUseCase() {
    return GetInvoicesUseCase(createRepository());
  }

  static GetInvoiceDetailsUseCase createGetInvoiceDetailsUseCase() {
    return GetInvoiceDetailsUseCase(createRepository());
  }

  static GetBillableTripsUseCase createGetBillableTripsUseCase() {
    return GetBillableTripsUseCase(createRepository());
  }

  static CreateInvoiceFromTripUseCase createInvoiceFromTripUseCase() {
    return CreateInvoiceFromTripUseCase(createRepository());
  }

  static CreateGroupedInvoiceUseCase createGroupedInvoiceUseCase() {
    return CreateGroupedInvoiceUseCase(createRepository());
  }

  static UpdateInvoiceDraftUseCase createUpdateInvoiceDraftUseCase() {
    return UpdateInvoiceDraftUseCase(createRepository());
  }

  static IssueInvoiceUseCase createIssueInvoiceUseCase() {
    return IssueInvoiceUseCase(
      createRepository(),
      businessDateProvider: CompanyDependencies.createBusinessDateProvider(),
    );
  }

  static CancelInvoiceUseCase createCancelInvoiceUseCase() {
    return CancelInvoiceUseCase(createRepository());
  }

  static GetInvoiceSettingsUseCase createGetSettingsUseCase() {
    return GetInvoiceSettingsUseCase(createSettingsRepository());
  }

  static UpdateInvoiceSettingsUseCase createUpdateSettingsUseCase() {
    return UpdateInvoiceSettingsUseCase(createSettingsRepository());
  }

  static InvoicesCubit createInvoicesCubit() {
    final repository = createRepository();
    return InvoicesCubit(
      getInvoicesUseCase: GetInvoicesUseCase(repository),
      getBillableTripsUseCase: GetBillableTripsUseCase(repository),
      createInvoiceFromTripUseCase: CreateInvoiceFromTripUseCase(repository),
      updateInvoiceDraftUseCase: UpdateInvoiceDraftUseCase(repository),
    );
  }
}
