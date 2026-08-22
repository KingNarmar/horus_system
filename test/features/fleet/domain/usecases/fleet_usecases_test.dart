import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_entity.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status.dart';
import 'package:horus_system/features/fleet/domain/policies/fleet_permission_policy.dart';
import 'package:horus_system/features/fleet/domain/repositories/fleet_repository.dart';
import 'package:horus_system/features/fleet/domain/usecases/fleet_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('CanManageFleetUseCase', () {
    test('returns the Domain permission policy result for every role', () async {
      const useCase = CanManageFleetUseCase();

      for (final role in CompanyRole.values) {
        final result = await useCase(
          CanManageFleetParams(currentCompanyContext: _context(role: role)),
        );

        expect(result, isA<Success<bool>>());
        expect(
          result.dataOrNull,
          FleetPermissionPolicy.canManageFleet(role),
          reason: 'Unexpected Fleet management result for $role',
        );
      }
    });
  });

  group('Fleet read use cases', () {
    test('denies unauthorized tractor-head view before repository call', () async {
      final repository = _FakeFleetRepository();
      final useCase = GetTractorHeadsUseCase(repository);

      final result = await useCase(
        GetFleetParams(
          currentCompanyContext: _context(role: CompanyRole.driver),
        ),
      );

      expect(result, isA<FailureResult<List<TractorHead>>>());
      expect(result.failureOrNull?.code, FailureCodes.permissionFleetView);
      expect(repository.getTractorHeadsCalls, 0);
    });

    test('authorized trailer read forwards exact company id', () async {
      final repository = _FakeFleetRepository();
      final useCase = GetTrailersUseCase(repository);

      final result = await useCase(
        GetFleetParams(
          currentCompanyContext: _context(
            companyId: '  company-1  ',
            role: CompanyRole.viewer,
          ),
        ),
      );

      expect(result, isA<Success<List<TrailerEntity>>>());
      expect(repository.getTrailersCalls, 1);
      expect(repository.lastCompanyId, '  company-1  ');
    });
  });

  group('SaveTractorHeadUseCase', () {
    test('denies unauthorized management before repository call', () async {
      final repository = _FakeFleetRepository();
      final useCase = SaveTractorHeadUseCase(repository);

      final result = await useCase(
        SaveTractorHeadParams(
          currentCompanyContext: _context(role: CompanyRole.accountant),
          plateNumber: 'T-100',
          status: VehicleStatus.available,
        ),
      );

      expect(result, isA<FailureResult<TractorHead>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionFleetManagement,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('requires plate number after trimming', () async {
      final repository = _FakeFleetRepository();
      final useCase = SaveTractorHeadUseCase(repository);

      final result = await useCase(
        SaveTractorHeadParams(
          currentCompanyContext: _context(),
          plateNumber: '   ',
          status: VehicleStatus.available,
        ),
      );

      expect(result, isA<FailureResult<TractorHead>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationFleetPlateRequired,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('rejects negative expected fuel consumption', () async {
      final repository = _FakeFleetRepository();
      final useCase = SaveTractorHeadUseCase(repository);

      final result = await useCase(
        SaveTractorHeadParams(
          currentCompanyContext: _context(),
          plateNumber: 'T-100',
          status: VehicleStatus.available,
          expectedFuelConsumption: -1,
        ),
      );

      expect(result, isA<FailureResult<TractorHead>>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationFleetFuelConsumptionNegative,
      );
      expect(repository.totalMutationCalls, 0);
    });

    test('blank id creates with normalized write data', () async {
      final repository = _FakeFleetRepository();
      final useCase = SaveTractorHeadUseCase(repository);

      final result = await useCase(
        SaveTractorHeadParams(
          currentCompanyContext: _context(),
          id: '   ',
          plateNumber: '  T-100  ',
          status: VehicleStatus.maintenance,
          expectedFuelConsumption: 32.5,
          notes: '  Workshop  ',
        ),
      );

      expect(result, isA<Success<TractorHead>>());
      expect(repository.addTractorHeadCalls, 1);
      expect(repository.saveTractorHeadCalls, 0);
      expect(repository.lastActorRole, CompanyRole.owner.value);
      final data = repository.lastTractorWriteData!;
      expect(data.companyId, _companyId);
      expect(data.plateNumber, 'T-100');
      expect(data.status, VehicleStatus.maintenance);
      expect(data.expectedFuelConsumption, 32.5);
      expect(data.notes, 'Workshop');
    });

    test('nonblank id updates using trimmed id and blank notes as null', () async {
      final repository = _FakeFleetRepository();
      final useCase = SaveTractorHeadUseCase(repository);

      final result = await useCase(
        SaveTractorHeadParams(
          currentCompanyContext: _context(role: CompanyRole.admin),
          id: '  tractor-1  ',
          plateNumber: 'T-200',
          status: VehicleStatus.available,
          notes: '   ',
        ),
      );

      expect(result, isA<Success<TractorHead>>());
      expect(repository.addTractorHeadCalls, 0);
      expect(repository.saveTractorHeadCalls, 1);
      expect(repository.lastAssetId, 'tractor-1');
      expect(repository.lastActorRole, CompanyRole.admin.value);
      expect(repository.lastTractorWriteData?.notes, isNull);
    });
  });

  group('SaveTrailerUseCase', () {
    test('creates with normalized plate and optional technical notes', () async {
      final repository = _FakeFleetRepository();
      final useCase = SaveTrailerUseCase(repository);

      final result = await useCase(
        SaveTrailerParams(
          currentCompanyContext: _context(role: CompanyRole.operations),
          plateNumber: '  TR-100  ',
          status: VehicleStatus.available,
          technicalNotes: '   ',
        ),
      );

      expect(result, isA<Success<TrailerEntity>>());
      expect(repository.addTrailerCalls, 1);
      expect(repository.lastActorRole, CompanyRole.operations.value);
      final data = repository.lastTrailerWriteData!;
      expect(data.plateNumber, 'TR-100');
      expect(data.technicalNotes, isNull);
    });
  });

  group('Fleet lifecycle use cases', () {
    test('tractor deactivate forwards company, id, and actor role', () async {
      final repository = _FakeFleetRepository();
      final useCase = DeactivateTractorHeadUseCase(repository);

      final result = await useCase(
        FleetAssetStatusParams(
          currentCompanyContext: _context(role: CompanyRole.operations),
          id: 'tractor-1',
        ),
      );

      expect(result, isA<Success<TractorHead>>());
      expect(repository.deactivateTractorHeadCalls, 1);
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastAssetId, 'tractor-1');
      expect(repository.lastActorRole, CompanyRole.operations.value);
    });

    test('trailer reactivate forwards company, id, and actor role', () async {
      final repository = _FakeFleetRepository();
      final useCase = ReactivateTrailerUseCase(repository);

      final result = await useCase(
        FleetAssetStatusParams(
          currentCompanyContext: _context(role: CompanyRole.owner),
          id: ' trailer-1 ',
        ),
      );

      expect(result, isA<Success<TrailerEntity>>());
      expect(repository.reactivateTrailerCalls, 1);
      expect(repository.lastCompanyId, _companyId);
      expect(repository.lastAssetId, ' trailer-1 ');
      expect(repository.lastActorRole, CompanyRole.owner.value);
    });
  });
}

const _companyId = 'company-1';

CurrentCompanyContext _context({
  String companyId = _companyId,
  CompanyRole role = CompanyRole.owner,
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Company'),
    role: role,
  );
}

const _tractor = TractorHead(
  id: 'tractor-1',
  companyId: _companyId,
  plateNumber: 'T-100',
  status: VehicleStatus.available,
  isActive: true,
);

const _trailer = TrailerEntity(
  id: 'trailer-1',
  companyId: _companyId,
  plateNumber: 'TR-100',
  status: VehicleStatus.available,
  isActive: true,
);

class _FakeFleetRepository implements FleetRepository {
  int getTractorHeadsCalls = 0;
  int getTrailersCalls = 0;
  int addTractorHeadCalls = 0;
  int saveTractorHeadCalls = 0;
  int deactivateTractorHeadCalls = 0;
  int reactivateTractorHeadCalls = 0;
  int addTrailerCalls = 0;
  int editTrailerCalls = 0;
  int deactivateTrailerCalls = 0;
  int reactivateTrailerCalls = 0;
  String? lastCompanyId;
  String? lastAssetId;
  String? lastActorRole;
  TractorHeadWriteData? lastTractorWriteData;
  TrailerWriteData? lastTrailerWriteData;

  int get totalMutationCalls =>
      addTractorHeadCalls +
      saveTractorHeadCalls +
      deactivateTractorHeadCalls +
      reactivateTractorHeadCalls +
      addTrailerCalls +
      editTrailerCalls +
      deactivateTrailerCalls +
      reactivateTrailerCalls;

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({
    required String companyId,
  }) async {
    getTractorHeadsCalls += 1;
    lastCompanyId = companyId;
    return const Success<List<TractorHead>>([_tractor]);
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({
    required String companyId,
  }) async {
    getTrailersCalls += 1;
    lastCompanyId = companyId;
    return const Success<List<TrailerEntity>>([_trailer]);
  }

  @override
  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  }) async {
    addTractorHeadCalls += 1;
    lastCompanyId = data.companyId;
    lastActorRole = actorRole;
    lastTractorWriteData = data;
    return Success<TractorHead>(
      TractorHead(
        id: _tractor.id,
        companyId: data.companyId,
        plateNumber: data.plateNumber,
        status: data.status,
        isActive: true,
        licenseExpiryDate: data.licenseExpiryDate,
        expectedFuelConsumption: data.expectedFuelConsumption,
        notes: data.notes,
      ),
    );
  }

  @override
  Future<Result<TractorHead>> saveTractorHead({
    required String id,
    required TractorHeadWriteData data,
    required String actorRole,
  }) async {
    saveTractorHeadCalls += 1;
    lastAssetId = id;
    lastCompanyId = data.companyId;
    lastActorRole = actorRole;
    lastTractorWriteData = data;
    return Success<TractorHead>(
      TractorHead(
        id: id,
        companyId: data.companyId,
        plateNumber: data.plateNumber,
        status: data.status,
        isActive: true,
        notes: data.notes,
      ),
    );
  }

  @override
  Future<Result<TractorHead>> deactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    deactivateTractorHeadCalls += 1;
    lastCompanyId = companyId;
    lastAssetId = id;
    lastActorRole = actorRole;
    return Success<TractorHead>(
      TractorHead(
        id: id,
        companyId: companyId,
        plateNumber: _tractor.plateNumber,
        status: _tractor.status,
        isActive: false,
      ),
    );
  }

  @override
  Future<Result<TractorHead>> reactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    reactivateTractorHeadCalls += 1;
    lastCompanyId = companyId;
    lastAssetId = id;
    lastActorRole = actorRole;
    return Success<TractorHead>(_tractor);
  }

  @override
  Future<Result<TrailerEntity>> addTrailer({
    required TrailerWriteData data,
    required String actorRole,
  }) async {
    addTrailerCalls += 1;
    lastCompanyId = data.companyId;
    lastActorRole = actorRole;
    lastTrailerWriteData = data;
    return Success<TrailerEntity>(
      TrailerEntity(
        id: _trailer.id,
        companyId: data.companyId,
        plateNumber: data.plateNumber,
        status: data.status,
        isActive: true,
        licenseExpiryDate: data.licenseExpiryDate,
        technicalNotes: data.technicalNotes,
      ),
    );
  }

  @override
  Future<Result<TrailerEntity>> editTrailer({
    required String id,
    required TrailerWriteData data,
    required String actorRole,
  }) async {
    editTrailerCalls += 1;
    lastAssetId = id;
    lastCompanyId = data.companyId;
    lastActorRole = actorRole;
    lastTrailerWriteData = data;
    return Success<TrailerEntity>(
      TrailerEntity(
        id: id,
        companyId: data.companyId,
        plateNumber: data.plateNumber,
        status: data.status,
        isActive: true,
        technicalNotes: data.technicalNotes,
      ),
    );
  }

  @override
  Future<Result<TrailerEntity>> deactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    deactivateTrailerCalls += 1;
    lastCompanyId = companyId;
    lastAssetId = id;
    lastActorRole = actorRole;
    return Success<TrailerEntity>(
      TrailerEntity(
        id: id,
        companyId: companyId,
        plateNumber: _trailer.plateNumber,
        status: _trailer.status,
        isActive: false,
      ),
    );
  }

  @override
  Future<Result<TrailerEntity>> reactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) async {
    reactivateTrailerCalls += 1;
    lastCompanyId = companyId;
    lastAssetId = id;
    lastActorRole = actorRole;
    return Success<TrailerEntity>(_trailer);
  }
}
