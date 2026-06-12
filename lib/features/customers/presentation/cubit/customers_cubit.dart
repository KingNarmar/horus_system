import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';
import '../../domain/policies/customers_permission_policy.dart';
import '../../domain/usecases/add_customer_usecase.dart';
import '../../domain/usecases/deactivate_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/reactivate_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final GetCustomersUseCase getCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeactivateCustomerUseCase deactivateCustomerUseCase;
  final ReactivateCustomerUseCase reactivateCustomerUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  CustomersCubit({
    required this.getCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deactivateCustomerUseCase,
    required this.reactivateCustomerUseCase,
  }) : super(const CustomersInitial());

  Future<void> loadCustomers(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final previousState = state;
    final previousSearchQuery = previousState is CustomersLoaded
        ? previousState.searchQuery
        : '';
    final previousStatusFilter = previousState is CustomersLoaded
        ? previousState.statusFilter
        : CustomerStatusFilter.active;

    emit(const CustomersLoading());

    final result = await getCustomersUseCase(
      GetCustomersParams(currentCompanyContext: currentCompanyContext),
    );

    result.when(
      success: (customers) => emit(
        CustomersLoaded(
          currentCompanyContext: currentCompanyContext,
          allCustomers: customers,
          searchQuery: previousSearchQuery,
          statusFilter: previousStatusFilter,
          canManageCustomers: CustomersPermissionPolicy.canManageCustomers(
            currentCompanyContext.role,
          ),
        ),
      ),
      failure: (failure) => emit(CustomersFailure(failure)),
    );
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(searchQuery: query));
    }
  }

  void setStatusFilter(CustomerStatusFilter statusFilter) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(statusFilter: statusFilter));
    }
  }

  Future<void> addCustomer({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? taxRegistrationNumber,
    String? address,
    String? city,
    String? country,
    double? creditLimit,
  }) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await addCustomerUseCase(
      AddCustomerParams(
        currentCompanyContext: currentCompanyContext,
        name: name,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        taxRegistrationNumber: taxRegistrationNumber,
        address: address,
        city: city,
        country: country,
        creditLimit: creditLimit,
      ),
    );

    await result.when(
      success: (_) => loadCustomers(currentCompanyContext),
      failure: (failure) async => emit(CustomersFailure(failure)),
    );
  }

  Future<void> updateCustomer({
    required Customer customer,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? taxRegistrationNumber,
    String? address,
    String? city,
    String? country,
    double? creditLimit,
  }) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await updateCustomerUseCase(
      UpdateCustomerParams(
        currentCompanyContext: currentCompanyContext,
        customerId: customer.id,
        name: name,
        contactPerson: contactPerson,
        phone: phone,
        email: email,
        taxRegistrationNumber: taxRegistrationNumber,
        address: address,
        city: city,
        country: country,
        creditLimit: creditLimit,
      ),
    );

    await result.when(
      success: (_) => loadCustomers(currentCompanyContext),
      failure: (failure) async => emit(CustomersFailure(failure)),
    );
  }

  Future<void> deactivateCustomer(Customer customer) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await deactivateCustomerUseCase(
      DeactivateCustomerParams(
        currentCompanyContext: currentCompanyContext,
        customerId: customer.id,
      ),
    );

    await result.when(
      success: (_) => loadCustomers(currentCompanyContext),
      failure: (failure) async => emit(CustomersFailure(failure)),
    );
  }

  Future<void> reactivateCustomer(Customer customer) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null) return;

    final result = await reactivateCustomerUseCase(
      ReactivateCustomerParams(
        currentCompanyContext: currentCompanyContext,
        customerId: customer.id,
      ),
    );

    await result.when(
      success: (_) => loadCustomers(currentCompanyContext),
      failure: (failure) async => emit(CustomersFailure(failure)),
    );
  }
}
