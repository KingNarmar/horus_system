import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../drivers/domain/entities/driver.dart';
import '../../domain/entities/driver_balance.dart';
import '../../domain/entities/driver_finance_trip_option.dart';
import '../../domain/entities/driver_financial_movement.dart';

const Object _notSet = Object();

sealed class DriverFinanceState {
  const DriverFinanceState();
}

final class DriverFinanceInitial extends DriverFinanceState {
  const DriverFinanceInitial();
}

final class DriverFinanceLoading extends DriverFinanceState {
  const DriverFinanceLoading();
}

final class DriverFinanceFailure extends DriverFinanceState {
  final Failure failure;

  const DriverFinanceFailure(this.failure);
}

final class DriverFinanceLoaded extends DriverFinanceState {
  final CurrentCompanyContext currentCompanyContext;
  final List<Driver> drivers;
  final String? selectedDriverId;
  final List<DriverFinancialMovement> movements;
  final DriverBalance? balance;
  final List<DriverFinanceTripOption> tripOptions;
  final bool canManage;
  final bool isDetailsLoading;
  final bool isSaving;
  final Failure? failure;

  const DriverFinanceLoaded({
    required this.currentCompanyContext,
    required this.drivers,
    required this.canManage,
    this.selectedDriverId,
    this.movements = const [],
    this.balance,
    this.tripOptions = const [],
    this.isDetailsLoading = false,
    this.isSaving = false,
    this.failure,
  });

  Driver? get selectedDriver {
    final id = selectedDriverId;
    if (id == null) return null;
    for (final driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  DriverFinanceLoaded copyWith({
    List<Driver>? drivers,
    Object? selectedDriverId = _notSet,
    List<DriverFinancialMovement>? movements,
    Object? balance = _notSet,
    List<DriverFinanceTripOption>? tripOptions,
    bool? canManage,
    bool? isDetailsLoading,
    bool? isSaving,
    Object? failure = _notSet,
  }) {
    return DriverFinanceLoaded(
      currentCompanyContext: currentCompanyContext,
      drivers: drivers ?? this.drivers,
      selectedDriverId: selectedDriverId == _notSet
          ? this.selectedDriverId
          : selectedDriverId as String?,
      movements: movements ?? this.movements,
      balance: balance == _notSet ? this.balance : balance as DriverBalance?,
      tripOptions: tripOptions ?? this.tripOptions,
      canManage: canManage ?? this.canManage,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isSaving: isSaving ?? this.isSaving,
      failure: failure == _notSet ? this.failure : failure as Failure?,
    );
  }
}
