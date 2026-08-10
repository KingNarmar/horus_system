import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../company/di/company_dependencies.dart';
import '../../invoices/di/invoices_dependencies.dart';
import '../../invoices/domain/usecases/invoice_query_usecases.dart';
import '../../payment_methods/di/payment_methods_dependencies.dart';
import '../../payment_methods/domain/usecases/get_active_payment_methods_usecase.dart';
import '../../payment_methods/domain/usecases/get_payment_methods_usecase.dart';
import '../data/datasources/payments_remote_data_source.dart';
import '../data/repositories/payments_repository_impl.dart';
import '../domain/repositories/payments_repository.dart';
import '../domain/usecases/get_payable_invoices_usecase.dart';
import '../domain/usecases/get_payment_business_date_usecase.dart';
import '../domain/usecases/get_payments_usecase.dart';
import '../domain/usecases/register_payment_usecase.dart';
import '../presentation/cubit/payments_cubit.dart';
import '../presentation/cubit/register_payment_cubit.dart';

abstract final class PaymentsDependencies {
  static PaymentsRepository createRepository() {
    return PaymentsRepositoryImpl(
      SupabasePaymentsRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static PaymentsCubit createPaymentsCubit() {
    final paymentsRepository = createRepository();
    final invoicesRepository = InvoicesDependencies.createRepository();
    final paymentMethodsRepository = PaymentMethodsDependencies.createRepository();

    return PaymentsCubit(
      getPaymentsUseCase: GetPaymentsUseCase(paymentsRepository),
      getInvoicesUseCase: GetInvoicesUseCase(invoicesRepository),
      getPaymentMethodsUseCase: GetPaymentMethodsUseCase(
        paymentMethodsRepository,
      ),
    );
  }

  static RegisterPaymentCubit createRegisterPaymentCubit() {
    final paymentsRepository = createRepository();
    final invoicesRepository = InvoicesDependencies.createRepository();
    final paymentMethodsRepository = PaymentMethodsDependencies.createRepository();
    final businessDateProvider = CompanyDependencies.createBusinessDateProvider();

    return RegisterPaymentCubit(
      getPayableInvoicesUseCase: GetPayableInvoicesUseCase(
        invoicesRepository: invoicesRepository,
        paymentsRepository: paymentsRepository,
      ),
      getActivePaymentMethodsUseCase: GetActivePaymentMethodsUseCase(
        paymentMethodsRepository,
      ),
      getPaymentBusinessDateUseCase: GetPaymentBusinessDateUseCase(
        businessDateProvider,
      ),
      registerPaymentUseCase: RegisterPaymentUseCase(
        paymentsRepository: paymentsRepository,
        invoicesRepository: invoicesRepository,
        paymentMethodsRepository: paymentMethodsRepository,
        businessDateProvider: businessDateProvider,
      ),
    );
  }
}
