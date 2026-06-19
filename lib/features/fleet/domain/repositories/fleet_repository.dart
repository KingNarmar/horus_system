import '../../../../core/utils/result.dart';
import '../entities/tractor_head.dart';
import '../entities/tractor_head_write_data.dart';
import '../entities/trailer_entity.dart';
import '../entities/trailer_write_data.dart';

abstract class FleetRepository {
  Future<Result<List<TractorHead>>> getTractorHeads({required String companyId});

  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId});

  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  });

  Future<Result<TractorHead>> saveTractorHead({
    required String id,
    required TractorHeadWriteData data,
    required String actorRole,
  });

  Future<Result<TractorHead>> deactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  });

  Future<Result<TractorHead>> reactivateTractorHead({
    required String companyId,
    required String id,
    required String actorRole,
  });

  Future<Result<TrailerEntity>> addTrailer({
    required TrailerWriteData data,
    required String actorRole,
  });

  Future<Result<TrailerEntity>> editTrailer({
    required String id,
    required TrailerWriteData data,
    required String actorRole,
  });

  Future<Result<TrailerEntity>> deactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  });

  Future<Result<TrailerEntity>> reactivateTrailer({
    required String companyId,
    required String id,
    required String actorRole,
  });
}
