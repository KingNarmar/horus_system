import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/fleet/data/datasources/fleet_remote_data_source.dart';
import 'package:horus_system/features/fleet/data/models/tractor_head_model.dart';
import 'package:horus_system/features/fleet/data/models/trailer_model.dart';
import 'package:horus_system/features/fleet/data/repositories/fleet_repo_impl.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head.dart';
import 'package:horus_system/features/fleet/domain/entities/tractor_head_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_entity.dart';
import 'package:horus_system/features/fleet/domain/entities/trailer_write_data.dart';
import 'package:horus_system/features/fleet/domain/entities/vehicle_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('FleetRepositoryImpl', () {
    test('trims company scope when loading both asset types', () async {
      final remoteDataSource = _FakeFleetRemoteDataSource();
      final repository = _repository(remoteDataSource);

      final tractors = await repository.getTractorHeads(
        companyId: '  $_companyId  ',
      );
      final trailers = await repository.getTrailers(
        companyId: '  $_companyId  ',
      );

      expect(tractors, isA<Success<List<TractorHead>>>());
      expect(trailers, isA<Success<List<TrailerEntity>>>());
      expect(remoteDataSource.lastTractorListCompanyId, _companyId);
      expect(remoteDataSource.lastTrailerListCompanyId, _companyId);
    });

    test('creates tractor head then writes audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addTractorHead(
        data: _tractorWriteData(plateNumber: 'T-NEW'),
        actorRole: 'operations',
      );

      expect(result, isA<Success<TractorHead>>());
      expect(result.dataOrNull?.plateNumber, 'T-NEW');
      expect(operations, ['add_tractor', 'audit']);
      expect(auditRepository.logs.single.description, 'tractor_head_created');
    });

    test('creates trailer then writes audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addTrailer(
        data: _trailerWriteData(plateNumber: 'TR-NEW'),
        actorRole: 'operations',
      );

      expect(result, isA<Success<TrailerEntity>>());
      expect(result.dataOrNull?.plateNumber, 'TR-NEW');
      expect(operations, ['add_trailer', 'audit']);
      expect(auditRepository.logs.single.description, 'trailer_created');
    });

    test('updates tractor after scoped old snapshot and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
        tractorOldModel: _tractorModel(plateNumber: 'T-OLD'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.saveTractorHead(
        id: _tractorId,
        data: _tractorWriteData(plateNumber: 'T-NEW'),
        actorRole: 'admin',
      );

      expect(result, isA<Success<TractorHead>>());
      expect(operations, ['get_tractor', 'save_tractor', 'audit']);
      expect(remoteDataSource.lastTractorLookupCompanyId, _companyId);
      expect(remoteDataSource.lastTractorLookupId, _tractorId);
      expect(auditRepository.logs.single.description, 'tractor_head_updated');
      expect(auditRepository.logs.single.oldValues?['plate_number'], 'T-OLD');
      expect(auditRepository.logs.single.newValues?['plate_number'], 'T-NEW');
    });

    test('updates trailer after scoped old snapshot and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
        trailerOldModel: _trailerModel(plateNumber: 'TR-OLD'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.editTrailer(
        id: _trailerId,
        data: _trailerWriteData(plateNumber: 'TR-NEW'),
        actorRole: 'admin',
      );

      expect(result, isA<Success<TrailerEntity>>());
      expect(operations, ['get_trailer', 'save_trailer', 'audit']);
      expect(remoteDataSource.lastTrailerLookupCompanyId, _companyId);
      expect(remoteDataSource.lastTrailerLookupId, _trailerId);
      expect(auditRepository.logs.single.description, 'trailer_updated');
      expect(auditRepository.logs.single.oldValues?['plate_number'], 'TR-OLD');
      expect(auditRepository.logs.single.newValues?['plate_number'], 'TR-NEW');
    });

    test('preserves tractor lifecycle sequencing and scope', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(
        remoteDataSource,
        auditRepository: _FakeAuditLogRepository(operations: operations),
      );

      final deactivated = await repository.deactivateTractorHead(
        companyId: _companyId,
        id: _tractorId,
        actorRole: 'owner',
      );
      final reactivated = await repository.reactivateTractorHead(
        companyId: _companyId,
        id: _tractorId,
        actorRole: 'owner',
      );

      expect(deactivated.dataOrNull?.isActive, isFalse);
      expect(reactivated.dataOrNull?.isActive, isTrue);
      expect(operations, [
        'get_tractor',
        'deactivate_tractor',
        'audit',
        'get_tractor',
        'reactivate_tractor',
        'audit',
      ]);
      expect(remoteDataSource.lastTractorLifecycleCompanyId, _companyId);
      expect(remoteDataSource.lastTractorLifecycleId, _tractorId);
    });

    test('preserves trailer lifecycle sequencing and scope', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(
        remoteDataSource,
        auditRepository: _FakeAuditLogRepository(operations: operations),
      );

      final deactivated = await repository.deactivateTrailer(
        companyId: _companyId,
        id: _trailerId,
        actorRole: 'owner',
      );
      final reactivated = await repository.reactivateTrailer(
        companyId: _companyId,
        id: _trailerId,
        actorRole: 'owner',
      );

      expect(deactivated.dataOrNull?.isActive, isFalse);
      expect(reactivated.dataOrNull?.isActive, isTrue);
      expect(operations, [
        'get_trailer',
        'deactivate_trailer',
        'audit',
        'get_trailer',
        'reactivate_trailer',
        'audit',
      ]);
      expect(remoteDataSource.lastTrailerLifecycleCompanyId, _companyId);
      expect(remoteDataSource.lastTrailerLifecycleId, _trailerId);
    });

    test('does not audit when mutation fails', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
        addTractorError: Exception('mutation failed'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addTractorHead(
        data: _tractorWriteData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<TractorHead>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_tractor']);
      expect(auditRepository.logs, isEmpty);
    });

    test('sanitizes Postgrest mutation failures without auditing', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
        addTractorError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
          details: 'internal policy details',
          hint: 'internal hint',
        ),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addTractorHead(
        data: _tractorWriteData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<TractorHead>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_tractor']);
      expect(auditRepository.logs, isEmpty);
    });

    test('propagates audit failure after successful mutation', () async {
      const failure = ValidationFailure(code: FailureCodes.serverError);
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(
        remoteDataSource,
        auditRepository: _FakeAuditLogRepository(
          operations: operations,
          failure: failure,
        ),
      );

      final result = await repository.addTrailer(
        data: _trailerWriteData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<TrailerEntity>>());
      expect(result.failureOrNull, same(failure));
      expect(operations, ['add_trailer', 'audit']);
    });

    test('sanitizes Postgrest failures through repository guard', () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(
          tractorListError: const PostgrestException(
            message: 'permission denied',
            code: '42501',
          ),
        ),
      );

      final result = await repository.getTractorHeads(companyId: _companyId);

      expect(result, isA<FailureResult<List<TractorHead>>>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes unexpected failures through repository guard', () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(trailerListError: StateError('bad list')),
      );

      final result = await repository.getTrailers(companyId: _companyId);

      expect(result, isA<FailureResult<List<TrailerEntity>>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('keeps tractor model mapping inside the sanitized guard', () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(
          tractorListModel: _ThrowingTractorHeadModel(),
        ),
      );

      final result = await repository.getTractorHeads(companyId: _companyId);

      expect(result, isA<FailureResult<List<TractorHead>>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('keeps trailer model mapping inside the sanitized guard', () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(trailerListModel: _ThrowingTrailerModel()),
      );

      final result = await repository.getTrailers(companyId: _companyId);

      expect(result, isA<FailureResult<List<TrailerEntity>>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

const _companyId = 'company-1';
const _tractorId = 'tractor-1';
const _trailerId = 'trailer-1';

FleetRepositoryImpl _repository(
  FleetRemoteDataSource remoteDataSource, {
  _FakeAuditLogRepository? auditRepository,
}) {
  return FleetRepositoryImpl(
    remoteDataSource: remoteDataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditLogRepository(),
    ),
  );
}

TractorHeadWriteData _tractorWriteData({String plateNumber = 'T-100'}) {
  return TractorHeadWriteData(
    companyId: _companyId,
    plateNumber: plateNumber,
    status: VehicleStatus.available,
    expectedFuelConsumption: 30,
    notes: 'Tractor notes',
  );
}

TrailerWriteData _trailerWriteData({String plateNumber = 'TR-100'}) {
  return TrailerWriteData(
    companyId: _companyId,
    plateNumber: plateNumber,
    status: VehicleStatus.available,
    technicalNotes: 'Trailer notes',
  );
}

TractorHeadModel _tractorModel({
  String plateNumber = 'T-100',
  bool isActive = true,
}) {
  return TractorHeadModel(
    id: _tractorId,
    companyId: _companyId,
    plateNumber: plateNumber,
    status: 'available',
    isActive: isActive,
  );
}

TrailerModel _trailerModel({
  String plateNumber = 'TR-100',
  bool isActive = true,
}) {
  return TrailerModel(
    id: _trailerId,
    companyId: _companyId,
    plateNumber: plateNumber,
    status: 'available',
    isActive: isActive,
  );
}

class _FakeFleetRemoteDataSource implements FleetRemoteDataSource {
  final List<String>? operations;
  final Object? tractorListError;
  final Object? trailerListError;
  final Object? addTractorError;
  final TractorHeadModel tractorListModel;
  final TrailerModel trailerListModel;
  final TractorHeadModel tractorOldModel;
  final TrailerModel trailerOldModel;

  String? lastTractorListCompanyId;
  String? lastTrailerListCompanyId;
  String? lastTractorLookupCompanyId;
  String? lastTractorLookupId;
  String? lastTrailerLookupCompanyId;
  String? lastTrailerLookupId;
  String? lastTractorLifecycleCompanyId;
  String? lastTractorLifecycleId;
  String? lastTrailerLifecycleCompanyId;
  String? lastTrailerLifecycleId;

  _FakeFleetRemoteDataSource({
    this.operations,
    this.tractorListError,
    this.trailerListError,
    this.addTractorError,
    TractorHeadModel? tractorListModel,
    TrailerModel? trailerListModel,
    TractorHeadModel? tractorOldModel,
    TrailerModel? trailerOldModel,
  }) : tractorListModel = tractorListModel ?? _tractorModel(),
       trailerListModel = trailerListModel ?? _trailerModel(),
       tractorOldModel = tractorOldModel ?? _tractorModel(),
       trailerOldModel = trailerOldModel ?? _trailerModel();

  @override
  Future<List<TractorHeadModel>> getTractorHeads({
    required String companyId,
  }) async {
    lastTractorListCompanyId = companyId;
    if (tractorListError != null) throw tractorListError!;
    return [tractorListModel];
  }

  @override
  Future<List<TrailerModel>> getTrailers({required String companyId}) async {
    lastTrailerListCompanyId = companyId;
    if (trailerListError != null) throw trailerListError!;
    return [trailerListModel];
  }

  @override
  Future<TractorHeadModel> getTractorHeadById({
    required String companyId,
    required String id,
  }) async {
    operations?.add('get_tractor');
    lastTractorLookupCompanyId = companyId;
    lastTractorLookupId = id;
    return tractorOldModel;
  }

  @override
  Future<TrailerModel> getTrailerById({
    required String companyId,
    required String id,
  }) async {
    operations?.add('get_trailer');
    lastTrailerLookupCompanyId = companyId;
    lastTrailerLookupId = id;
    return trailerOldModel;
  }

  @override
  Future<TractorHeadModel> addTractorHead({
    required TractorHeadWriteData data,
  }) async {
    operations?.add('add_tractor');
    if (addTractorError != null) throw addTractorError!;
    return _tractorModel(plateNumber: data.plateNumber);
  }

  @override
  Future<TractorHeadModel> saveTractorHead({
    required String id,
    required TractorHeadWriteData data,
  }) async {
    operations?.add('save_tractor');
    return _tractorModel(plateNumber: data.plateNumber);
  }

  @override
  Future<TractorHeadModel> deactivateTractorHead({
    required String companyId,
    required String id,
  }) async {
    operations?.add('deactivate_tractor');
    lastTractorLifecycleCompanyId = companyId;
    lastTractorLifecycleId = id;
    return _tractorModel(isActive: false);
  }

  @override
  Future<TractorHeadModel> reactivateTractorHead({
    required String companyId,
    required String id,
  }) async {
    operations?.add('reactivate_tractor');
    lastTractorLifecycleCompanyId = companyId;
    lastTractorLifecycleId = id;
    return _tractorModel(isActive: true);
  }

  @override
  Future<TrailerModel> addTrailer({required TrailerWriteData data}) async {
    operations?.add('add_trailer');
    return _trailerModel(plateNumber: data.plateNumber);
  }

  @override
  Future<TrailerModel> editTrailer({
    required String id,
    required TrailerWriteData data,
  }) async {
    operations?.add('save_trailer');
    return _trailerModel(plateNumber: data.plateNumber);
  }

  @override
  Future<TrailerModel> deactivateTrailer({
    required String companyId,
    required String id,
  }) async {
    operations?.add('deactivate_trailer');
    lastTrailerLifecycleCompanyId = companyId;
    lastTrailerLifecycleId = id;
    return _trailerModel(isActive: false);
  }

  @override
  Future<TrailerModel> reactivateTrailer({
    required String companyId,
    required String id,
  }) async {
    operations?.add('reactivate_trailer');
    lastTrailerLifecycleCompanyId = companyId;
    lastTrailerLifecycleId = id;
    return _trailerModel(isActive: true);
  }
}

class _ThrowingTractorHeadModel extends TractorHeadModel {
  _ThrowingTractorHeadModel()
    : super(
        id: _tractorId,
        companyId: _companyId,
        plateNumber: 'T-THROW',
        status: 'available',
        isActive: true,
      );

  @override
  String get status => throw StateError('internal tractor mapping failure');
}

class _ThrowingTrailerModel extends TrailerModel {
  _ThrowingTrailerModel()
    : super(
        id: _trailerId,
        companyId: _companyId,
        plateNumber: 'TR-THROW',
        status: 'available',
        isActive: true,
      );

  @override
  String get status => throw StateError('internal trailer mapping failure');
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure, this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    if (failure != null) return FailureResult<void>(failure!);
    logs.add(data);
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
