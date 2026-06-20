import '../../../../core/utils/result.dart';
import '../entities/route_entity.dart';
import '../entities/route_write_data.dart';

abstract class RoutesRepository {
  Future<Result<List<RouteEntity>>> getRoutes({required String companyId});

  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
  });

  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
  });

  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  });

  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
  });
}
