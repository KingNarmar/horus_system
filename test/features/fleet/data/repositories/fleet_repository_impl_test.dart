import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
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

    test(
      'creates tractor head through the server-audited mutation path',
      () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addTractorHead(
        data: _tractorWriteData(),
        actorRole: 'operations',
      );

      expect(result, isA<Success<TractorHead>>());
      expect(operations, ['add_tractor']);
      },
    );

    test('creates trailer through the server-audited mutation path', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addTrailer(
        data: _trailerWriteData(),
        actorRole: 'operations',
      );

      expect(result, isA<Success<TrailerEntity>>());
      expect(operations, ['add_trailer']);
    });

    test('updates assets without redundant audit snapshot lookups', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final tractor = await repository.saveTractorHead(
        id: _tractorId,
        data: _tractorWriteData(plateNumber: 'T-NEW'),
        actorRole: 'admin',
      );
      expect(tractor.dataOrNull?.plateNumber, 'T-NEW');
      expect(operations, ['save_tractor']);

      operations.clear();
      final trailer = await repository.editTrailer(
        id: _trailerId,
        data: _trailerWriteData(plateNumber: 'TR-NEW'),
        actorRole: 'admin',
      );
      expect(trailer.dataOrNull?.plateNumber, 'TR-NEW');
      expect(operations, ['save_trailer']);
    });

    test('preserves lifecycle company scope without audit lookups', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeFleetRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final tractor = await repository.deactivateTractorHead(
        companyId: _companyId,
        id: _tractorId,
        actorRole: 'owner',
      );
      expect(tractor.dataOrNull?.isActive, isFalse);
      expect(operations, ['deactivate_tractor']);
      expect(remoteDataSource.lastTractorLifecycleCompanyId, _companyId);

      operations.clear();
      final trailer = await repository.reactivateTrailer(
        companyId: _companyId,
        id: _trailerId,
        actorRole: 'owner',
      );
      expect(trailer.dataOrNull?.isActive, isTrue);
      expect(operations, ['reactivate_trailer']);
      expect(remoteDataSource.lastTrailerLifecycleCompanyId, _companyId);
    });

    test('sanitizes Postgrest mutation failures', () async {
      final remoteDataSource = _FakeFleetRemoteDataSource(
        addTractorError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
        ),
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addTractorHead(
        data: _tractorWriteData(),
        actorRole: 'operations',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test(
      'sanitizes Postgrest read failures through repository guard',
      () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(
          tractorListError: const PostgrestException(
            message: 'read denied',
            code: '42501',
          ),
        ),
      );

      final result = await repository.getTractorHeads(companyId: _companyId);

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
      },
    );

    test(
      'sanitizes unexpected read failures through repository guard',
      () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(
          trailerListError: StateError('internal trailer read failure'),
        ),
      );

      final result = await repository.getTrailers(companyId: _companyId);

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      },
    );

    test('keeps tractor model mapping inside the sanitized guard', () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(
          tractorListModel: _ThrowingTractorHeadModel(),
        ),
      );

      final result = await repository.getTractorHeads(companyId: _companyId);

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
    });

    test('keeps trailer model mapping inside the sanitized guard', () async {
      final repository = _repository(
        _FakeFleetRemoteDataSource(trailerListModel: _ThrowingTrailerModel()),
      );

      final result = await repository.getTrailers(companyId: _companyId);

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
    });
  });
}

const _companyId = 'company-1';
const _tractorId = 'tractor-1';
const _trailerId = 'trailer-1';

FleetRepositoryImpl _repository(FleetRemoteDataSource remoteDataSource) {
  return FleetRepositoryImpl(remoteDataSource: remoteDataSource);
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

