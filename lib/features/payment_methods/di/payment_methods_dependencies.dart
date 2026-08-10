import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../data/datasources/payment_methods_remote_data_source.dart';
import '../data/repositories/payment_methods_repository_impl.dart';
import '../domain/repositories/payment_methods_repository.dart';
import '../domain/usecases/add_payment_method_usecase.dart';
import '../domain/usecases/deactivate_payment_method_usecase.dart';
import '../domain/usecases/get_active_payment_methods_usecase.dart';
import '../domain/usecases/get_payment_methods_usecase.dart';
import '../domain/usecases/reactivate_payment_method_usecase.dart';
import '../domain/usecases/update_payment_method_usecase.dart';
import '../presentation/cubit/payment_methods_cubit.dart';

abstract final class PaymentMethodsDependencies {
  static PaymentMethodsRepository createRepository() {
    final remoteDataSource = SupabasePaymentMethodsRemoteDataSource(
      SupabaseClientProvider.client,
    );
    return PaymentMethodsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static PaymentMethodsCubit createCubit() {
    final repository = createRepository();
    return PaymentMethodsCubit(
      getPaymentMethodsUseCase: GetPaymentMethodsUseCase(repository),
      addPaymentMethodUseCase: AddPaymentMethodUseCase(repository),
      updatePaymentMethodUseCase: UpdatePaymentMethodUseCase(repository),
      deactivatePaymentMethodUseCase: DeactivatePaymentMethodUseCase(repository),
      reactivatePaymentMethodUseCase: ReactivatePaymentMethodUseCase(repository),
    );
  }

  static GetActivePaymentMethodsUseCase createGetActivePaymentMethodsUseCase() {
    return GetActivePaymentMethodsUseCase(createRepository());
  }
}
