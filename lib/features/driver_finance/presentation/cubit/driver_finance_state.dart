import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../drivers/domain/entities/driver.dart';
import '../../domain/entities/driver_balance_activity.dart';
import '../../domain/entities/driver_finance_trip_option.dart';

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
  final DriverBalanceActivity? activity;
  final List<DriverFinanceTripOption> tripOptions;
  final bool canManage;
  final bool isDetailsLoading;
  final bool isSaving;
  final Failure? failure;
  final Failure? realtimeRefreshFailure;

  const DriverFinanceLoaded({
    required this.currentCompanyContext,
    required this.drivers,
    required this.canManage,
    this.selectedDriverId,
    this.activity,
    this.tripOptions = const [],
    this.isDetailsLoading = false,
    this.isSaving = false,
    this.failure,
    this.realtimeRefreshFailure,
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
    Object? activity = _notSet,
    List<DriverFinanceTripOption>? tripOptions,
    bool? canManage,
    bool? isDetailsLoading,
    bool? isSaving,
    Object? failure = _notSet,
    Object? realtimeRefreshFailure = _notSet,
  }) {
    return DriverFinanceLoaded(
      currentCompanyContext: currentCompanyContext,
      drivers: drivers ?? this.drivers,
      selectedDriverId: selectedDriverId == _notSet
          ? this.selectedDriverId
          : selectedDriverId as String?,
      activity: activity == _notSet
          ? this.activity
          : activity as DriverBalanceActivity?,
      tripOptions: tripOptions ?? this.tripOptions,
      canManage: canManage ?? this.canManage,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      isSaving: isSaving ?? this.isSaving,
      failure: failure == _notSet ? this.failure : failure as Failure?,
      realtimeRefreshFailure: realtimeRefreshFailure == _notSet
          ? this.realtimeRefreshFailure
          : realtimeRefreshFailure as Failure?,
    );
  }
}
