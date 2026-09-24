import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_write_data.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_remote_data_source.dart';
import '../mappers/route_mapper.dart';
import '../models/route_model.dart';
import 'route_repository_failure_mapper.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesRemoteDataSource remoteDataSource;
  final RouteRepositoryFailureMapper _failureMapper;

  const RoutesRepositoryImpl({
    required this.remoteDataSource,
  }) : _failureMapper = const RouteRepositoryFailureMapper();


  @override
  Future<Result<List<RouteEntity>>> getRoutes({
    required String companyId,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getRoutes(companyId: companyId);
      return Success(
        models
            .map(
              (model) => model.toEntity(
                financialConfiguration: financialConfiguration,
              ),
            )
            .toList(),
      );
    });
  }

  @override
  Future<Result<RouteEntity>> addRoute({
    required RouteWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addRoute(
        data: data,
        financialConfiguration: financialConfiguration,
      );
      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    });
  }

  @override
  Future<Result<RouteEntity>> saveRoute({
    required String id,
    required RouteWriteData data,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.saveRoute(
        id: id,
        data: data,
        financialConfiguration: financialConfiguration,
      );
      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
    });
  }

  @override
  Future<Result<RouteEntity>> deactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _changeActiveState(
      companyId: companyId,
      id: id,
      financialConfiguration: financialConfiguration,
      change: remoteDataSource.deactivateRoute,
    );
  }

  @override
  Future<Result<RouteEntity>> reactivateRoute({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
  }) {
    return _changeActiveState(
      companyId: companyId,
      id: id,
      financialConfiguration: financialConfiguration,
      change: remoteDataSource.reactivateRoute,
    );
  }

  Future<Result<RouteEntity>> _changeActiveState({
    required String companyId,
    required String id,
    required CurrencyConfiguration? financialConfiguration,
    required Future<RouteModel> Function({
      required String companyId,
      required String id,
    })
    change,
  }) {
    return _guard(() async {
      final model = await change(companyId: companyId, id: id);
      return Success(
        model.toEntity(financialConfiguration: financialConfiguration),
      );
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
