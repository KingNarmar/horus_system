import '../../../../core/utils/result.dart';
import '../entities/tractor_head.dart';
import '../entities/tractor_head_write_data.dart';
import '../entities/trailer_entity.dart';

abstract class FleetRepository {
  Future<Result<List<TractorHead>>> getTractorHeads({required String companyId});

  Future<Result<List<TrailerEntity>>> getTrailers({required String companyId});

  Future<Result<TractorHead>> addTractorHead({
    required TractorHeadWriteData data,
    required String actorRole,
  });
}
