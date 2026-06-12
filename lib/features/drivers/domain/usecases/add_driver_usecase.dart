import 'package:horus_system/core/errors/failure_codes.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../entities/driver.dart';
import '../entities/driver_write_data.dart';
import '../policies/drivers_permission_policy.dart';
import '../repositories/drivers_repository.dart';

class AddDriverParams {
  final CurrentCompanyContext currentCompanyContext;
  final String fullName;
  final String? phone;
  final String? nationalId;
  final String? licenseNumber;
  final DateTime? licenseExpiryDate;
  final String? notes;

  const AddDriverParams({
    required this.currentCompanyContext,
    required this.fullName,
    this.phone,
    this.nationalId,
    this.licenseNumber,
    this.licenseExpiryDate,
    this.notes,
  });
}

class AddDriverUseCase implements UseCase<Driver, AddDriverParams> {
  final DriversRepository _repository;

  const AddDriverUseCase(this._repository);

  @override
  Future<Result<Driver>> call(AddDriverParams params) {
    final context = params.currentCompanyContext;
    if (!DriversPermissionPolicy.canManageDrivers(context.role)) {
      return Future.value(
        const FailureResult<Driver>(
          PermissionFailure(code: FailureCodes.permissionDriversManagement, message: 'Drivers management is not allowed.'),
        ),
      );
    }

    final fullName = params.fullName.trim();
    if (fullName.isEmpty) {
      return Future.value(
        const FailureResult<Driver>(
          ValidationFailure(code: FailureCodes.validationDriverNameRequired, message: 'Driver name is required.'),
        ),
      );
    }

    return _repository.addDriver(
      actorRole: context.role.value,
      data: DriverWriteData(
        companyId: context.companyId,
        fullName: fullName,
        phone: _normalizeOptional(params.phone),
        nationalId: _normalizeOptional(params.nationalId),
        licenseNumber: _normalizeOptional(params.licenseNumber),
        licenseExpiryDate: params.licenseExpiryDate,
        notes: _normalizeOptional(params.notes),
      ),
    );
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
