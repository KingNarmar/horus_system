import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/tractor_head_write_data.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/trailer_write_data.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_remote_data_source.dart';
import '../mappers/tractor_mapper.dart';
import '../mappers/trailers_mapper.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FleetRemoteDataSource remoteDataSource;

  const FleetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getTractorHeads(companyId: companyId.trim());
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getTrailers(companyId: companyId.trim());
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<TractorHead>> addTractorHead({required TractorHeadWriteData data, required String actorRole}) {
    return _guard(() async {
      final model = await remoteDataSource.addTractorHead(data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TractorHead>> saveTractorHead({required String id, required TractorHeadWriteData data, required String actorRole}) {
    return _guard(() async {
      final model = await remoteDataSource.saveTractorHead(id: id, data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> addTrailer({required TrailerWriteData data, required String actorRole}) {
    return _guard(() async {
      final model = await remoteDataSource.addTrailer(data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<TrailerEntity>> editTrailer({required String id, required TrailerWriteData data, required String actorRole}) {
    return _guard(() async {
      final model = await remoteDataSource.editTrailer(id: id, data: data);
      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(
          code: error.code ?? FailureCodes.serverError,
          message: error.message,
        ),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
