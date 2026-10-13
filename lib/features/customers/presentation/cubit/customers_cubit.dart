import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_status_filter.dart';
import '../../domain/usecases/add_customer_usecase.dart';
import '../../domain/usecases/can_manage_customers_usecase.dart';
import '../../domain/usecases/deactivate_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/reactivate_customer_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final GetCustomersUseCase getCustomersUseCase;
  final CanManageCustomersUseCase canManageCustomersUseCase;
  final AddCustomerUseCase addCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeactivateCustomerUseCase deactivateCustomerUseCase;
  final ReactivateCustomerUseCase reactivateCustomerUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;

  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;
  int _activityRequestId = 0;
  int _loadRequestId = 0;
  bool _isRealtimeRefreshing = false;
  bool _realtimeRefreshPending = false;

  CurrentCompanyContext? _currentCompanyContext;

  CustomersCubit({
    required this.getCustomersUseCase,
    required this.canManageCustomersUseCase,
    required this.addCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deactivateCustomerUseCase,
    required this.reactivateCustomerUseCase,
    required this.getEntityAuditLogsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
  }) : super(const CustomersInitial());

  Future<void> loadCustomers(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    _currentCompanyContext = currentCompanyContext;
    final loadRequestId = ++_loadRequestId;
    ++_activityRequestId;
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

    if (isClosed || loadRequestId != _loadRequestId) return;

    final loadFailure = result.failureOrNull;
    if (loadFailure != null) {
      emit(CustomersFailure(loadFailure));
      return;
    }

    final permissionResult = await canManageCustomersUseCase(
      CanManageCustomersParams(currentCompanyContext: currentCompanyContext),
    );
    if (isClosed || loadRequestId != _loadRequestId) return;

    final permissionFailure = permissionResult.failureOrNull;
    if (permissionFailure != null) {
      emit(CustomersFailure(permissionFailure));
      return;
    }

    emit(
      CustomersLoaded(
        currentCompanyContext: currentCompanyContext,
        allCustomers: result.dataOrNull ?? const [],
        searchQuery: previousSearchQuery,
        statusFilter: previousStatusFilter,
        canManageCustomers: permissionResult.dataOrNull ?? false,
      ),
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

  Future<void> loadCustomerActivity(Customer customer) async {
    final current = state;
    if (isClosed || current is! CustomersLoaded) return;
    final context = current.currentCompanyContext;
    if (customer.companyId != context.companyId) return;
    final requestId = ++_activityRequestId;
    emit(
      current.copyWith(
        selectedCustomer: customer,
        selectedCustomerActivity: const [],
        selectedCustomerActivityTimestampsByLogId: const {},
        isActivityLoading: true,
        activityFailure: null,
      ),
    );
    final result = await getEntityAuditLogsUseCase(
      GetEntityAuditLogsParams(
        companyId: context.companyId,
        module: AuditModule.customers,
        entityType: AuditEntityType.customer,
        entityId: customer.id,
      ),
    );
    if (!_isCurrentActivity(requestId, context.companyId, customer.id)) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      emit(
        (state as CustomersLoaded).copyWith(
          isActivityLoading: false,
          activityFailure: failure,
        ),
      );
      return;
    }
    final activity = result.dataOrNull!;
    final projected = await convertInstantsToBusinessLocalDateTimesUseCase(
      ConvertInstantsToBusinessLocalDateTimesParams(
        timeZoneId: context.company.businessTimezone ?? '',
        instantsByKey: {for (final log in activity) log.id: log.createdAt},
      ),
    );
    if (!_isCurrentActivity(requestId, context.companyId, customer.id)) return;
    final latest = state as CustomersLoaded;
    final projectionFailure = projected.failureOrNull;
    if (projectionFailure != null) {
      emit(
        latest.copyWith(
          isActivityLoading: false,
          activityFailure: projectionFailure,
        ),
      );
      return;
    }
    emit(
      latest.copyWith(
        selectedCustomerActivity: activity,
        selectedCustomerActivityTimestampsByLogId: projected.dataOrNull!,
        isActivityLoading: false,
        activityFailure: null,
      ),
    );
  }

  bool _isCurrentActivity(int requestId, String companyId, String entityId) {
    final current = state;
    return !isClosed &&
        requestId == _activityRequestId &&
        current is CustomersLoaded &&
        current.currentCompanyContext.companyId == companyId &&
        current.selectedCustomer?.id == entityId;
  }

  void clearCustomerActivity() {
    ++_activityRequestId;
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(
        currentState.copyWith(
          selectedCustomer: null,
          selectedCustomerActivity: const [],
          selectedCustomerActivityTimestampsByLogId: const {},
          isActivityLoading: false,
          activityFailure: null,
        ),
      );
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

    if (!_isCurrentMutationContext(currentCompanyContext)) return;
    result.when(
      success: _upsertCustomer,
      failure: (failure) => emit(CustomersFailure(failure)),
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

    if (!_isCurrentMutationContext(currentCompanyContext)) return;
    result.when(
      success: _upsertCustomer,
      failure: (failure) => emit(CustomersFailure(failure)),
    );
  }

  Future<void> deactivateCustomer(Customer customer) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null || !_startPendingAction(customer.id)) {
      return;
    }

    final result = await deactivateCustomerUseCase(
      DeactivateCustomerParams(
        currentCompanyContext: currentCompanyContext,
        customerId: customer.id,
      ),
    );

    if (!_isCurrentMutationContext(currentCompanyContext)) return;
    result.when(success: _upsertCustomer, failure: _emitMutationFailure);
  }

  Future<void> reactivateCustomer(Customer customer) async {
    final currentCompanyContext = _currentCompanyContext;
    if (currentCompanyContext == null || !_startPendingAction(customer.id)) {
      return;
    }

    final result = await reactivateCustomerUseCase(
      ReactivateCustomerParams(
        currentCompanyContext: currentCompanyContext,
        customerId: customer.id,
      ),
    );

    if (!_isCurrentMutationContext(currentCompanyContext)) return;
    result.when(success: _upsertCustomer, failure: _emitMutationFailure);
  }

  bool _startPendingAction(String customerId) {
    final currentState = state;
    if (currentState is! CustomersLoaded) return true;
    if (currentState.pendingActionCustomerId != null) return false;

    emit(currentState.copyWith(pendingActionCustomerId: customerId));
    return true;
  }

  void _emitMutationFailure(Failure failure) {
    final currentState = state;
    if (currentState is CustomersLoaded) {
      emit(currentState.copyWith(pendingActionCustomerId: null));
    }
    emit(CustomersFailure(failure));
  }

  bool _isCurrentMutationContext(CurrentCompanyContext expected) {
    final current = _currentCompanyContext;
    return !isClosed &&
        current?.companyId == expected.companyId &&
        current?.role == expected.role;
  }

  void _upsertCustomer(Customer customer) {
    final currentState = state;
    final currentCompanyContext = _currentCompanyContext;
    if (isClosed || customer.companyId != currentCompanyContext?.companyId) {
      return;
    }
    if (currentState is CustomersLoaded &&
        currentState.currentCompanyContext.companyId != customer.companyId) {
      return;
    }

    if (currentState is! CustomersLoaded) {
      if (currentCompanyContext != null) loadCustomers(currentCompanyContext);
      return;
    }

    final exists = currentState.allCustomers.any(
      (item) => item.id == customer.id,
    );
    final updatedCustomers = exists
        ? currentState.allCustomers
              .map((item) => item.id == customer.id ? customer : item)
              .toList()
        : [customer, ...currentState.allCustomers];

    if (currentState.selectedCustomer?.id == customer.id) {
      emit(
        currentState.copyWith(
          allCustomers: updatedCustomers,
          pendingActionCustomerId: null,
          selectedCustomer: customer,
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        allCustomers: updatedCustomers,
        pendingActionCustomerId: null,
      ),
    );
  }

  /// Reloads changed records without resetting the user's search and filters.
  /// Coalesces simultaneous server signals into at most one follow-up read.
  Future<void> refreshCustomers(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    if (_isRealtimeRefreshing) {
      if (_currentCompanyContext?.companyId ==
          currentCompanyContext.companyId) {
        _realtimeRefreshPending = true;
      }
      return;
    }

    _isRealtimeRefreshing = true;
    try {
      do {
        _realtimeRefreshPending = false;
        await _refreshCustomersOnce(currentCompanyContext);
      } while (_realtimeRefreshPending &&
          !isClosed &&
          _currentCompanyContext?.companyId == currentCompanyContext.companyId);
    } finally {
      _isRealtimeRefreshing = false;
    }
  }

  Future<void> _refreshCustomersOnce(
    CurrentCompanyContext currentCompanyContext,
  ) async {
    if (isClosed ||
        _currentCompanyContext?.companyId != currentCompanyContext.companyId) {
      return;
    }

    final previous = state;
    if (previous is! CustomersLoaded) {
      await loadCustomers(currentCompanyContext);
      return;
    }

    final requestId = ++_loadRequestId;
    final result = await getCustomersUseCase(
      GetCustomersParams(currentCompanyContext: currentCompanyContext),
    );

    if (isClosed || requestId != _loadRequestId) return;
    final latest = state;
    if (latest is! CustomersLoaded ||
        latest.currentCompanyContext.companyId !=
            currentCompanyContext.companyId) {
      return;
    }

    final failure = result.failureOrNull;
    if (failure != null) {
      emit(latest.copyWith(refreshFailure: failure));
      return;
    }

    final customers = result.dataOrNull ?? const <Customer>[];
    Customer? selectedCustomer = latest.selectedCustomer;
    final selectedCustomerId = selectedCustomer?.id;
    if (selectedCustomerId != null) {
      for (final item in customers) {
        if (item.id == selectedCustomerId) {
          selectedCustomer = item;
          break;
        }
      }
    }

    emit(
      latest.copyWith(
        allCustomers: customers,
        selectedCustomer: selectedCustomer,
        refreshFailure: null,
      ),
    );
  }
}
