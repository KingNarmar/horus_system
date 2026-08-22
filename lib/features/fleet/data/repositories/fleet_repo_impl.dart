import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/tractor_head_write_data.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/trailer_write_data.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_remote_data_source.dart';
import '../mappers/tractor_mapper.dart';
import '../mappers/trailers_mapper.dart';
import '../models/tractor_head_model.dart';
import '../models/trailer_model.dart';
import 'fleet_repository_audit_writer.dart';
import 'fleet_repository_failure_mapper.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FleetRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final FleetRepositoryFailureMapper _failureMapper;

  const FleetRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const FleetRepositoryFailureMapper();

  FleetRepositoryAuditWriter get _auditWriter {
    return FleetRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getTractorHeads(
        companyId: companyId.trim(),
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getTrailers(
        companyId: companyId.trim(),
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addTractorHead(data: data);
      final auditFailure = await _auditWriter.writeTractorHeadCreated(
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<TractorHead>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TractorHead>> saveTractorHead({
    required String id,
    required TractorHeadWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTractorHeadById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.saveTractorHead(id: id, data: data);
      final auditFailure = await _auditWriter.writeTractorHeadUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<TractorHead>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TractorHead>> deactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _changeTractorHeadActiveState(
      companyId: companyId,
      id: id,
      actorRole: actorRole,
      change: remoteDataSource.deactivateTractorHead,
      writeAudit: _auditWriter.writeTractorHeadDeactivated,
    );
  }

  @override
  Future<Result<TractorHead>> reactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _changeTractorHeadActiveState(
      companyId: companyId,
      id: id,
      actorRole: actorRole,
      change: remoteDataSource.reactivateTractorHead,
      writeAudit: _auditWriter.writeTractorHeadReactivated,
    );
  }

  @override
  Future<Result<TrailerEntity>> addTrailer({
    required TrailerWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addTrailer(data: data);
      final auditFailure = await _auditWriter.writeTrailerCreated(
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<TrailerEntity>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> editTrailer({
    required String id,
    required TrailerWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTrailerById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.editTrailer(id: id, data: data);
      final auditFailure = await _auditWriter.writeTrailerUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<TrailerEntity>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> deactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _changeTrailerActiveState(
      companyId: companyId,
      id: id,
      actorRole: actorRole,
      change: remoteDataSource.deactivateTrailer,
      writeAudit: _auditWriter.writeTrailerDeactivated,
    );
  }

  @override
  Future<Result<TrailerEntity>> reactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  }) {
    return _changeTrailerActiveState(
      companyId: companyId,
      id: id,
      actorRole: actorRole,
      change: remoteDataSource.reactivateTrailer,
      writeAudit: _auditWriter.writeTrailerReactivated,
    );
  }

  Future<Result<TractorHead>> _changeTractorHeadActiveState({
    required String companyId,
    required String id,
    required String actorRole,
    required Future<TractorHeadModel> Function({
      required String companyId,
      required String id,
    })
    change,
    required Future<Failure?> Function({
      required TractorHeadModel oldModel,
      required TractorHeadModel model,
      required String actorRole,
    })
    writeAudit,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTractorHeadById(
        companyId: companyId,
        id: id,
      );
      final model = await change(companyId: companyId, id: id);
      final auditFailure = await writeAudit(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<TractorHead>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  Future<Result<TrailerEntity>> _changeTrailerActiveState({
    required String companyId,
    required String id,
    required String actorRole,
    required Future<TrailerModel> Function({
      required String companyId,
      required String id,
    })
    change,
    required Future<Failure?> Function({
      required TrailerModel oldModel,
      required TrailerModel model,
      required String actorRole,
    })
    writeAudit,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getTrailerById(
        companyId: companyId,
        id: id,
      );
      final model = await change(companyId: companyId, id: id);
      final auditFailure = await writeAudit(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) {
        return FailureResult<TrailerEntity>(auditFailure);
      }
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
