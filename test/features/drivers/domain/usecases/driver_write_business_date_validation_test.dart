import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/drivers/domain/entities/driver.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_file.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_urls.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:horus_system/features/drivers/domain/repositories/drivers_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/add_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/update_driver_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('driver license expiry business-date validation', () {
    final businessDate = BusinessDate(year: 2026, month: 9, day: 19);
    final expiredDate = BusinessDate(year: 2026, month: 9, day: 18);

    test('add rejects an expiry date before the business date', () async {
      final repository = _FakeDriversRepository();
      final result = await AddDriverUseCase(repository)(
        AddDriverParams(
          currentCompanyContext: _context,
          fullName: 'Driver',
          licenseExpiryDate: expiredDate,
          currentBusinessDate: businessDate,
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverLicenseExpiryBeforeBusinessDate,
      );
      expect(repository.addCalls, 0);
    });

    test('update rejects an expiry date before the business date', () async {
      final repository = _FakeDriversRepository();
      final result = await UpdateDriverUseCase(repository)(
        UpdateDriverParams(
          currentCompanyContext: _context,
          driverId: 'driver-1',
          fullName: 'Driver',
          licenseExpiryDate: expiredDate,
          currentBusinessDate: businessDate,
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverLicenseExpiryBeforeBusinessDate,
      );
      expect(repository.updateCalls, 0);
    });

    test('same-day expiry is accepted and forwarded', () async {
      final repository = _FakeDriversRepository();
      final result = await AddDriverUseCase(repository)(
        AddDriverParams(
          currentCompanyContext: _context,
          fullName: 'Driver',
          licenseExpiryDate: businessDate,
          currentBusinessDate: businessDate,
        ),
      );

      expect(result, isA<Success<Driver>>());
      expect(repository.addCalls, 1);
      expect(repository.lastWriteData?.licenseExpiryDate, businessDate);
    });
  });
}

const _context = CurrentCompanyContext(
  company: Company(id: 'company-1', name: 'Company'),
  role: CompanyRole.owner,
);

class _FakeDriversRepository implements DriversRepository {
  int addCalls = 0;
  int updateCalls = 0;
  DriverWriteData? lastWriteData;

  @override
  Future<Result<Driver>> addDriver({
    required DriverWriteData data,
    required String actorRole,
    DriverImageUploadSet? imageUploads,
  }) async {
    addCalls++;
    lastWriteData = data;
    return Success(_driver(data));
  }

  @override
  Future<Result<Driver>> updateDriver({
    required String driverId,
    required DriverWriteData data,
    required String actorRole,
    DriverImageUploadSet? imageUploads,
  }) async {
    updateCalls++;
    lastWriteData = data;
    return Success(_driver(data, id: driverId));
  }

  @override
  Future<Result<List<Driver>>> getDrivers({required String companyId}) async {
    return const Success([]);
  }

  @override
  Future<Result<DriverImageUrls>> getDriverImageUrls({
    required Driver driver,
  }) async {
    return const Success(DriverImageUrls.empty);
  }

  @override
  Future<Result<Driver>> deactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Driver>> reactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  Driver _driver(DriverWriteData data, {String id = 'driver-1'}) {
    return Driver(
      id: id,
      companyId: data.companyId,
      fullName: data.fullName,
      licenseExpiryDate: data.licenseExpiryDate,
      status: DriverStatus.active,
    );
  }
}
