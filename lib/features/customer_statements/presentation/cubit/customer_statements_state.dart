import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../domain/entities/customer_statement.dart';

sealed class CustomerStatementsState {
  const CustomerStatementsState();
}

final class CustomerStatementsInitial extends CustomerStatementsState {
  const CustomerStatementsInitial();
}

final class CustomerStatementsLoadingCustomers extends CustomerStatementsState {
  const CustomerStatementsLoadingCustomers();
}

final class CustomerStatementsLoadFailure extends CustomerStatementsState {
  final Failure failure;

  const CustomerStatementsLoadFailure(this.failure);
}

final class CustomerStatementsReady extends CustomerStatementsState {
  static const Object _unset = Object();

  final CurrentCompanyContext currentCompanyContext;
  final List<Customer> customers;
  final String? selectedCustomerId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final CustomerStatement? statement;
  final bool isLoadingStatement;
  final Failure? statementFailure;

  const CustomerStatementsReady({
    required this.currentCompanyContext,
    required this.customers,
    this.selectedCustomerId,
    this.fromDate,
    this.toDate,
    this.statement,
    this.isLoadingStatement = false,
    this.statementFailure,
  });

  Customer? get selectedCustomer {
    final id = selectedCustomerId;
    if (id == null) return null;
    for (final customer in customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  bool get canApply => selectedCustomer != null && !isLoadingStatement;

  CustomerStatementsReady copyWith({
    Object? selectedCustomerId = _unset,
    Object? fromDate = _unset,
    Object? toDate = _unset,
    Object? statement = _unset,
    bool? isLoadingStatement,
    Object? statementFailure = _unset,
  }) {
    return CustomerStatementsReady(
      currentCompanyContext: currentCompanyContext,
      customers: customers,
      selectedCustomerId: identical(selectedCustomerId, _unset)
          ? this.selectedCustomerId
          : selectedCustomerId as String?,
      fromDate: identical(fromDate, _unset)
          ? this.fromDate
          : fromDate as DateTime?,
      toDate: identical(toDate, _unset) ? this.toDate : toDate as DateTime?,
      statement: identical(statement, _unset)
          ? this.statement
          : statement as CustomerStatement?,
      isLoadingStatement: isLoadingStatement ?? this.isLoadingStatement,
      statementFailure: identical(statementFailure, _unset)
          ? this.statementFailure
          : statementFailure as Failure?,
    );
  }
}
