import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';

const Object _notSet = Object();

sealed class CustomersState {
  const CustomersState();
}

class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

class CustomersLoaded extends CustomersState {
  final CurrentCompanyContext currentCompanyContext;
  final List<Customer> allCustomers;
  final bool canManageCustomers;
  final String searchQuery;
  final CustomerStatusFilter statusFilter;
  final Customer? selectedCustomer;
  final List<AuditLog> selectedCustomerActivity;
  final bool isActivityLoading;
  final Failure? activityFailure;

  const CustomersLoaded({
    required this.currentCompanyContext,
    required this.allCustomers,
    required this.canManageCustomers,
    this.searchQuery = '',
    this.statusFilter = CustomerStatusFilter.active,
    this.selectedCustomer,
    this.selectedCustomerActivity = const [],
    this.isActivityLoading = false,
    this.activityFailure,
  });

  List<Customer> get customers {
    final normalizedSearch = searchQuery.trim().toLowerCase();

    return allCustomers.where((customer) {
      if (!statusFilter.matches(customer)) return false;
      if (normalizedSearch.isEmpty) return true;

      return customer.name.toLowerCase().contains(normalizedSearch) ||
          (customer.contactPerson?.toLowerCase().contains(normalizedSearch) ??
              false) ||
          (customer.phone?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (customer.email?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (customer.city?.toLowerCase().contains(normalizedSearch) ?? false) ||
          (customer.country?.toLowerCase().contains(normalizedSearch) ??
              false) ||
          (customer.taxRegistrationNumber?.toLowerCase().contains(
                    normalizedSearch,
                  ) ??
              false);
    }).toList();
  }

  CustomersLoaded copyWith({
    List<Customer>? allCustomers,
    bool? canManageCustomers,
    String? searchQuery,
    CustomerStatusFilter? statusFilter,
    Object? selectedCustomer = _notSet,
    List<AuditLog>? selectedCustomerActivity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
  }) {
    return CustomersLoaded(
      currentCompanyContext: currentCompanyContext,
      allCustomers: allCustomers ?? this.allCustomers,
      canManageCustomers: canManageCustomers ?? this.canManageCustomers,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedCustomer: selectedCustomer == _notSet
          ? this.selectedCustomer
          : selectedCustomer as Customer?,
      selectedCustomerActivity:
          selectedCustomerActivity ?? this.selectedCustomerActivity,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
    );
  }
}

class CustomersFailure extends CustomersState {
  final Failure failure;

  const CustomersFailure(this.failure);
}
