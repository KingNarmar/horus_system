import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/utils/result.dart';
import '../entities/route_entity.dart';
import '../entities/route_write_data.dart';

abstract class RoutesRepository {
  Future<Result<List<RouteEntity>>> getRoutes({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  });

  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
  });
}
