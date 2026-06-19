import '../../../../core/utils/result.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/tractor_head_write_data.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/repositories/fleet_repository.dart';
import '../datasources/fleet_remote_data_source.dart';
import '../mappers/tractor_mapper.dart';
import '../mappers/trailers_mapper.dart';

class FleetRepositoryImpl implements FleetRepository {
  final FleetRemoteDataSource remoteDataSource;

  const FleetRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<TractorHead>>> getTractorHeads({required String companyId}) async {
    final models = await remoteDataSource.getTractorHeads(companyId: companyId);
    return Success(models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId}) async {
    final models = await remoteDataSource.getTrailers(companyId: companyId);
    return Success(models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<Result<TractorHead>> addTractorHead({required TractorHeadWriteData data, required String actorRole}) async {
    final model = await remoteDataSource.addTractorHead(data: data);
    return Success(model.toEntity());
  }

  @override
  Future<Result<TractorHead>> saveTractorHead({required String id, required TractorHeadWriteData data, required String actorRole}) async {
    final model = await remoteDataSource.saveTractorHead(id: id, data: data);
    return Success(model.toEntity());
  }
}
