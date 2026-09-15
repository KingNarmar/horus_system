import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/domain/value_objects/currency_configuration.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/route_write_data.dart';
import '../../domain/repositories/routes_repository.dart';
import '../datasources/routes_remote_data_source.dart';
import '../mappers/route_mapper.dart';
import '../models/route_model.dart';
import 'route_repository_audit_writer.dart';
import 'route_repository_failure_mapper.dart';

class RoutesRepositoryImpl implements RoutesRepository {
  final RoutesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final RouteRepositoryFailureMapper _failureMapper;

  const RoutesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const RouteRepositoryFailureMapper();

  RouteRepositoryAuditWriter get _auditWriter {
    return RouteRepositoryAuditWriter(createAuditLogUseCase);
  }

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
      final auditFailure = await _auditWriter.writeCreated(
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<RouteEntity>(auditFailure);
      }
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
      final oldModel = await remoteDataSource.getRouteById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.saveRoute(
        id: id,
        data: data,
        financialConfiguration: financialConfiguration,
      );
      final auditFailure = await _auditWriter.writeUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<RouteEntity>(auditFailure);
      }
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
      actorRole: actorRole,
      financialConfiguration: financialConfiguration,
      change: remoteDataSource.deactivateRoute,
      writeAudit: _auditWriter.writeDeactivated,
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
      actorRole: actorRole,
      financialConfiguration: financialConfiguration,
      change: remoteDataSource.reactivateRoute,
      writeAudit: _auditWriter.writeReactivated,
    );
  }

  Future<Result<RouteEntity>> _changeActiveState({
    required String companyId,
    required String id,
    required String actorRole,
    required CurrencyConfiguration? financialConfiguration,
    required Future<RouteModel> Function({
      required String companyId,
      required String id,
    })
    change,
    required Future<Failure?> Function({
      required RouteModel oldModel,
      required RouteModel model,
      required String actorRole,
    })
    writeAudit,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getRouteById(
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
        return FailureResult<RouteEntity>(auditFailure);
      }
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
