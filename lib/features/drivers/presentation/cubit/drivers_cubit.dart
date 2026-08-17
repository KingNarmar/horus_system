import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../driver_finance/domain/entities/driver_financial_movement.dart';
import '../../../driver_finance/domain/policies/driver_finance_permission_policy.dart';
import '../../../driver_finance/domain/usecases/driver_finance_usecases.dart';
import '../../../driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../../domain/entities/driver_image_urls.dart';
import '../../domain/entities/driver_status_filter.dart';
import '../../domain/policies/drivers_permission_policy.dart';
import '../../domain/usecases/add_driver_usecase.dart';
import '../../domain/usecases/deactivate_driver_usecase.dart';
import '../../domain/usecases/get_driver_image_urls_usecase.dart';
import '../../domain/usecases/get_drivers_usecase.dart';
import '../../domain/usecases/reactivate_driver_usecase.dart';
import '../../domain/usecases/update_driver_usecase.dart';
import 'drivers_state.dart';

part 'drivers_filter_actions.dart';
part 'drivers_finance_actions.dart';
part 'drivers_mutation_actions.dart';
part 'drivers_selected_driver_actions.dart';

class DriversCubit extends Cubit<DriversState>
    with
        DriversFilterActions,
        DriversSelectedDriverActions,
        DriversFinanceActions,
        DriversMutationActions {
  final GetDriversUseCase getDriversUseCase;
  final GetDriverImageUrlsUseCase getDriverImageUrlsUseCase;
  final AddDriverUseCase addDriverUseCase;
  final UpdateDriverUseCase updateDriverUseCase;
  final DeactivateDriverUseCase deactivateDriverUseCase;
  final ReactivateDriverUseCase reactivateDriverUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;
  final GetDriverMovementsUseCase getDriverMovementsUseCase;
  final GetDriverTripOptionsUseCase getDriverTripOptionsUseCase;
  final AddDriverAdvanceUseCase addDriverAdvanceUseCase;
  final AddDriverChargeUseCase addDriverChargeUseCase;
  final AddDriverCashReturnUseCase addDriverCashReturnUseCase;
  final GetCanonicalDriverBalanceUseCase getCanonicalDriverBalanceUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  DriversCubit({
    required this.getDriversUseCase,
    required this.getDriverImageUrlsUseCase,
    required this.addDriverUseCase,
    required this.updateDriverUseCase,
    required this.deactivateDriverUseCase,
    required this.reactivateDriverUseCase,
    required this.getEntityAuditLogsUseCase,
    required this.getDriverMovementsUseCase,
    required this.getDriverTripOptionsUseCase,
    required this.addDriverAdvanceUseCase,
    required this.addDriverChargeUseCase,
    required this.addDriverCashReturnUseCase,
    required this.getCanonicalDriverBalanceUseCase,
  }) : super(const DriversInitial());

  Future<void> loadDrivers(CurrentCompanyContext currentCompanyContext) async {
    _currentCompanyContext = currentCompanyContext;
    final previousState = state;
    final previousSearchQuery = previousState is DriversLoaded
        ? previousState.searchQuery
        : '';
    final previousStatusFilter = previousState is DriversLoaded
        ? previousState.statusFilter
        : DriverStatusFilter.active;

    emit(const DriversLoading());

    final result = await getDriversUseCase(
      GetDriversParams(currentCompanyContext: currentCompanyContext),
    );

    result.when(
      success: (drivers) => emit(
        DriversLoaded(
          currentCompanyContext: currentCompanyContext,
          allDrivers: drivers,
          searchQuery: previousSearchQuery,
          statusFilter: previousStatusFilter,
          canManageDrivers: DriversPermissionPolicy.canManageDrivers(
            currentCompanyContext.role,
          ),
          canManageDriverFinance:
              DriverFinancePermissionPolicy.canManageDriverFinance(
                currentCompanyContext.role,
              ),
        ),
      ),
      failure: (failure) => emit(DriversFailure(failure)),
    );
  }
}
