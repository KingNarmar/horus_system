import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/domain/value_objects/business_local_date_time.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../../core/usecases/get_company_business_date_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/entities/audit_entity_type.dart';
import '../../../audit/domain/entities/audit_module.dart';
import '../../../audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/driver.dart';
import '../../domain/entities/driver_image_file.dart';
import '../../domain/entities/driver_image_urls.dart';
import '../../domain/entities/driver_status_filter.dart';
import '../../domain/usecases/add_driver_usecase.dart';
import '../../domain/usecases/can_manage_drivers_usecase.dart';
import '../../domain/usecases/deactivate_driver_usecase.dart';
import '../../domain/usecases/get_driver_image_urls_usecase.dart';
import '../../domain/usecases/get_drivers_usecase.dart';
import '../../domain/usecases/reactivate_driver_usecase.dart';
import '../../domain/usecases/update_driver_usecase.dart';
import 'drivers_state.dart';

part 'drivers_filter_actions.dart';
part 'drivers_mutation_actions.dart';
part 'drivers_selected_driver_actions.dart';

class DriversCubit extends Cubit<DriversState>
    with
        DriversFilterActions,
        DriversSelectedDriverActions,
        DriversMutationActions {
  final GetDriversUseCase getDriversUseCase;
  final CanManageDriversUseCase canManageDriversUseCase;
  final GetDriverImageUrlsUseCase getDriverImageUrlsUseCase;
  final AddDriverUseCase addDriverUseCase;
  final UpdateDriverUseCase updateDriverUseCase;
  final DeactivateDriverUseCase deactivateDriverUseCase;
  final ReactivateDriverUseCase reactivateDriverUseCase;
  final GetEntityAuditLogsUseCase getEntityAuditLogsUseCase;
  final ConvertInstantsToBusinessLocalDateTimesUseCase
  convertInstantsToBusinessLocalDateTimesUseCase;
  final GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase;

  CurrentCompanyContext? _currentCompanyContext;

  DriversCubit({
    required this.getDriversUseCase,
    required this.canManageDriversUseCase,
    required this.getDriverImageUrlsUseCase,
    required this.addDriverUseCase,
    required this.updateDriverUseCase,
    required this.deactivateDriverUseCase,
    required this.reactivateDriverUseCase,
    required this.getEntityAuditLogsUseCase,
    required this.convertInstantsToBusinessLocalDateTimesUseCase,
    required this.getCompanyBusinessDateUseCase,
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

    final loadFailure = result.failureOrNull;
    if (loadFailure != null) {
      emit(DriversFailure(loadFailure));
      return;
    }

    final permissionResult = await canManageDriversUseCase(
      CanManageDriversParams(currentCompanyContext: currentCompanyContext),
    );
    final permissionFailure = permissionResult.failureOrNull;
    if (permissionFailure != null) {
      emit(DriversFailure(permissionFailure));
      return;
    }

    emit(
      DriversLoaded(
        currentCompanyContext: currentCompanyContext,
        allDrivers: result.dataOrNull ?? const [],
        searchQuery: previousSearchQuery,
        statusFilter: previousStatusFilter,
        canManageDrivers: permissionResult.dataOrNull ?? false,
      ),
    );
  }

  Future<Result<BusinessDate>> getCurrentBusinessDate() {
    final context = _currentCompanyContext;
    if (context == null) {
      return Future.value(
        const FailureResult<BusinessDate>(UnexpectedFailure()),
      );
    }
    return getCompanyBusinessDateUseCase(
      GetCompanyBusinessDateParams(companyId: context.companyId),
    );
  }

  Future<Result<Map<String, BusinessLocalDateTime>>> _convertCompanyInstants(
    CurrentCompanyContext currentCompanyContext,
    Map<String, DateTime> instantsByKey,
  ) {
    return convertInstantsToBusinessLocalDateTimesUseCase(
      ConvertInstantsToBusinessLocalDateTimesParams(
        timeZoneId: currentCompanyContext.company.businessTimezone ?? '',
        instantsByKey: instantsByKey,
      ),
    );
  }
}
