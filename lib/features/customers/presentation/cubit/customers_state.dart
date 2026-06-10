import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';

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
  final List<Customer> customers;
  final bool canManageCustomers;

  const CustomersLoaded({
    required this.currentCompanyContext,
    required this.customers,
    required this.canManageCustomers,
  });
}

class CustomersFailure extends CustomersState {
  final Failure failure;

  const CustomersFailure(this.failure);
}
