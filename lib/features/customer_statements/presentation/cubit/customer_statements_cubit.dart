import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../company/domain/entities/current_company_context.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../customers/domain/usecases/get_customers_usecase.dart';
import '../../domain/entities/customer_statement.dart';
import '../../domain/usecases/customer_statement_params.dart';
import '../../domain/usecases/get_customer_statement_usecase.dart';
import 'customer_statements_state.dart';

final class CustomerStatementsCubit extends Cubit<CustomerStatementsState> {
  final GetCustomersUseCase getCustomersUseCase;
  final GetCustomerStatementUseCase getCustomerStatementUseCase;

  CurrentCompanyContext? _currentCompanyContext;
  int _customersRequestId = 0;
  int _statementRequestId = 0;
  bool _invoiceReconcilePending = false;
  bool _invoiceReconcileInProgress = false;

  CustomerStatementsCubit({
    required this.getCustomersUseCase,
    required this.getCustomerStatementUseCase,
  }) : super(const CustomerStatementsInitial());

  Future<void> load(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final requestId = ++_customersRequestId;
    ++_statementRequestId;
    emit(const CustomerStatementsLoadingCustomers());

    final result = await getCustomersUseCase(
      GetCustomersParams(currentCompanyContext: currentCompanyContext),
    );

    if (!_isCurrentCustomersRequest(
      requestId,
      currentCompanyContext.companyId,
    )) {
      return;
    }

    result.when(
      success: (customers) => emit(
        CustomerStatementsReady(
          currentCompanyContext: currentCompanyContext,
          customers: List.unmodifiable(customers),
        ),
      ),
      failure: (failure) => emit(CustomerStatementsLoadFailure(failure)),
    );
    _drainInvoiceReconciliation();
  }

  void selectCustomer(String? customerId) {
    final current = state;
    if (current is! CustomerStatementsReady) return;

    final normalized = customerId?.trim();
    final selectedId =
        normalized != null &&
            normalized.isNotEmpty &&
            current.customers.any((customer) => customer.id == normalized)
        ? normalized
        : null;

    _invalidateStatement();
    emit(
      current.copyWith(
        selectedCustomerId: selectedId,
        statement: null,
        statementFailure: null,
        isLoadingStatement: false,
      ),
    );
  }

  void setFromDate(DateTime? date) {
    final current = state;
    if (current is! CustomerStatementsReady) return;
    _invalidateStatement();
    emit(
      current.copyWith(
        fromDate: _dateOnlyOrNull(date),
        statement: null,
        statementFailure: null,
        isLoadingStatement: false,
      ),
    );
  }

  void setToDate(DateTime? date) {
    final current = state;
    if (current is! CustomerStatementsReady) return;
    _invalidateStatement();
    emit(
      current.copyWith(
        toDate: _dateOnlyOrNull(date),
        statement: null,
        statementFailure: null,
        isLoadingStatement: false,
      ),
    );
  }

  void clearDates() {
    final current = state;
    if (current is! CustomerStatementsReady) return;
    _invalidateStatement();
    emit(
      current.copyWith(
        fromDate: null,
        toDate: null,
        statement: null,
        statementFailure: null,
        isLoadingStatement: false,
      ),
    );
  }

  Future<void> apply() async {
    final current = state;
    if (current is! CustomerStatementsReady || !current.canApply) return;

    final customer = current.selectedCustomer;
    if (customer == null) return;

    final requestId = ++_statementRequestId;
    final companyId = current.currentCompanyContext.companyId;
    final customerId = customer.id;

    emit(
      current.copyWith(
        isLoadingStatement: true,
        statement: null,
        statementFailure: null,
      ),
    );

    final result = await getCustomerStatementUseCase(
      GetCustomerStatementParams(
        currentCompanyContext: current.currentCompanyContext,
        customerId: customerId,
        fromDate: current.fromDate,
        toDate: current.toDate,
      ),
    );

    final latest = state;
    if (isClosed ||
        latest is! CustomerStatementsReady ||
        requestId != _statementRequestId ||
        latest.currentCompanyContext.companyId != companyId ||
        latest.selectedCustomerId != customerId) {
      return;
    }

    result.when(
      success: (CustomerStatement statement) => emit(
        latest.copyWith(
          statement: statement,
          isLoadingStatement: false,
          statementFailure: null,
        ),
      ),
      failure: (failure) => emit(
        latest.copyWith(
          statement: null,
          isLoadingStatement: false,
          statementFailure: failure,
        ),
      ),
    );
    _drainInvoiceReconciliation();
  }

  /// Recalculate only a visible, previously requested statement. Keep the
  /// selected customer, date filters and old statement on refresh failures.
  Future<void> reconcileStatementAfterInvoiceChange() async {
    _invoiceReconcilePending = true;
    if (_invoiceReconcileInProgress) return;
    _invoiceReconcileInProgress = true;
    try {
      while (_invoiceReconcilePending && !isClosed) {
        _invoiceReconcilePending = false;
        final current = state;
        if (current is! CustomerStatementsReady || current.isLoadingStatement) {
          _invoiceReconcilePending = true;
          break;
        }
        if (current.statement == null || current.selectedCustomerId == null) {
          break;
        }
        final requestId = ++_statementRequestId;
        final companyId = current.currentCompanyContext.companyId;
        final customerId = current.selectedCustomerId!;
        final result = await getCustomerStatementUseCase(
          GetCustomerStatementParams(
            currentCompanyContext: current.currentCompanyContext,
            customerId: customerId,
            fromDate: current.fromDate,
            toDate: current.toDate,
          ),
        );
        final latest = state;
        if (latest is! CustomerStatementsReady ||
            isClosed ||
            requestId != _statementRequestId ||
            latest.currentCompanyContext.companyId != companyId ||
            latest.selectedCustomerId != customerId) {
          break;
        }
        final failure = result.failureOrNull;
        if (failure != null &&
            (failure is AuthFailure || failure is PermissionFailure)) {
          emit(CustomerStatementsLoadFailure(failure));
          break;
        }
        result.when(
          success: (statement) => emit(
            latest.copyWith(statement: statement, statementFailure: null),
          ),
          failure: (failure) =>
              emit(latest.copyWith(statementFailure: failure)),
        );
      }
    } finally {
      _invoiceReconcileInProgress = false;
    }
  }

  void _drainInvoiceReconciliation() {
    if (_invoiceReconcilePending) {
      unawaited(reconcileStatementAfterInvoiceChange());
    }
  }

  void _invalidateStatement() {
    ++_statementRequestId;
  }

  bool _isCurrentCustomersRequest(int requestId, String companyId) {
    return !isClosed &&
        requestId == _customersRequestId &&
        _currentCompanyContext?.companyId == companyId;
  }

  DateTime? _dateOnlyOrNull(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day);
  }
}
