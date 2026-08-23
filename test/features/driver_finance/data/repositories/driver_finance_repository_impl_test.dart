import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/driver_finance/data/datasources/driver_finance_remote_data_source.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_finance_trip_option_model.dart';
import 'package:horus_system/features/driver_finance/data/models/driver_financial_movement_model.dart';
import 'package:horus_system/features/driver_finance/data/repositories/driver_finance_repository_impl.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  group('DriverFinanceRepositoryImpl', () {
    test('loads movements with exact company and driver scope', () async {
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        movements: [_movementModel()],
      );
      final repository = _repository(dataSource);

      final result = await repository.getDriverMovements(
        companyId: _companyId,
        driverId: _driverId,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull?.single.id, _movementId);
      expect(
        result.dataOrNull?.single.type,
        DriverFinancialMovementType.advance,
      );
      expect(dataSource.lastMovementCompanyId, _companyId);
      expect(dataSource.lastMovementDriverId, _driverId);
    });

    test('loads trip options with exact company and driver scope', () async {
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        tripOptions: const [
          DriverFinanceTripOptionModel(id: _tripId, label: 'Trip 1'),
        ],
      );
      final repository = _repository(dataSource);

      final result = await repository.getDriverTripOptions(
        companyId: _companyId,
        driverId: _driverId,
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.single.id, _tripId);
      expect(result.dataOrNull?.single.label, 'Trip 1');
      expect(dataSource.lastTripOptionCompanyId, _companyId);
      expect(dataSource.lastTripOptionDriverId, _driverId);
    });

    test('adds movement then writes audit then returns entity', () async {
      final operations = <String>[];
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        operations: operations,
        addedMovement: _movementModel(),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = DriverFinanceRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );
      final writeData = _writeData();

      final result = await repository.addDriverMovement(
        data: writeData,
        actorRole: 'accountant',
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull?.id, _movementId);
      expect(operations, ['add_movement', 'audit']);
      expect(dataSource.lastWriteData, same(writeData));
      expect(auditRepository.logs.single.companyId, _companyId);
      expect(auditRepository.logs.single.entityId, _driverId);
      expect(auditRepository.logs.single.metadata?['movement_id'], _movementId);
    });

    test('does not write audit when movement persistence fails', () async {
      final operations = <String>[];
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        operations: operations,
        addError: Exception('insert failed'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = DriverFinanceRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addDriverMovement(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(operations, ['add_movement']);
      expect(auditRepository.logs, isEmpty);
    });

    test('propagates audit failure after successful persistence', () async {
      final operations = <String>[];
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        operations: operations,
        addedMovement: _movementModel(),
      );
      final auditRepository = _FakeAuditLogRepository(
        operations: operations,
        result: const FailureResult<void>(
          ServerFailure(
            code: FailureCodes.serverError,
            message: 'audit failed',
          ),
        ),
      );
      final repository = DriverFinanceRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addDriverMovement(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(operations, ['add_movement', 'audit']);
    });

    test('maps movement Postgrest failures without audit', () async {
      final operations = <String>[];
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        operations: operations,
        addError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
        ),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = DriverFinanceRepositoryImpl(
        remoteDataSource: dataSource,
        createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
      );

      final result = await repository.addDriverMovement(
        data: _writeData(),
        actorRole: 'accountant',
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, '42501');
      expect(result.failureOrNull?.message, 'permission denied');
      expect(operations, ['add_movement']);
      expect(auditRepository.logs, isEmpty);
    });

    test('maps unexpected read failures', () async {
      final dataSource = _FakeDriverFinanceRemoteDataSource(
        tripOptionReadError: Exception('read failed'),
      );
      final repository = _repository(dataSource);

      final result = await repository.getDriverTripOptions(
        companyId: _companyId,
        driverId: _driverId,
      );

      expect(result, isA<FailureResult>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, 'Exception: read failed');
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';
const _tripId = 'trip-1';
const _movementId = 'movement-1';

DriverFinanceRepositoryImpl _repository(
  DriverFinanceRemoteDataSource dataSource,
) {
  return DriverFinanceRepositoryImpl(
    remoteDataSource: dataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(_FakeAuditLogRepository()),
  );
}

DriverFinancialMovementModel _movementModel() {
  return DriverFinancialMovementModel(
    id: _movementId,
    companyId: _companyId,
    driverId: _driverId,
    tripId: _tripId,
    type: DriverFinancialMovementType.advance,
    amount: 125.5,
    movementDate: DateTime.utc(2026, 8, 23),
    notes: 'note',
    createdAt: DateTime.utc(2026, 8, 23, 9),
    updatedAt: DateTime.utc(2026, 8, 23, 10),
  );
}

DriverFinancialMovementWriteData _writeData() {
  return DriverFinancialMovementWriteData(
    companyId: _companyId,
    driverId: _driverId,
    tripId: _tripId,
    type: DriverFinancialMovementType.advance,
    amount: 125.5,
    movementDate: DateTime.utc(2026, 8, 23),
    notes: 'note',
  );
}

class _FakeDriverFinanceRemoteDataSource
    implements DriverFinanceRemoteDataSource {
  final List<String>? operations;
  final List<DriverFinancialMovementModel> movements;
  final List<DriverFinanceTripOptionModel> tripOptions;
  final DriverFinancialMovementModel? addedMovement;
  final Object? tripOptionReadError;
  final Object? addError;

  String? lastMovementCompanyId;
  String? lastMovementDriverId;
  String? lastTripOptionCompanyId;
  String? lastTripOptionDriverId;
  DriverFinancialMovementWriteData? lastWriteData;

  _FakeDriverFinanceRemoteDataSource({
    this.operations,
    this.movements = const [],
    this.tripOptions = const [],
    this.addedMovement,
    this.tripOptionReadError,
    this.addError,
  });

  @override
  Future<List<DriverFinancialMovementModel>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) async {
    lastMovementCompanyId = companyId;
    lastMovementDriverId = driverId;
    return movements;
  }

  @override
  Future<List<DriverFinanceTripOptionModel>> getDriverTripOptions({
    required String companyId,
    required String driverId,
  }) async {
    lastTripOptionCompanyId = companyId;
    lastTripOptionDriverId = driverId;
    if (tripOptionReadError != null) throw tripOptionReadError!;
    return tripOptions;
  }

  @override
  Future<DriverFinancialMovementModel> addDriverMovement({
    required DriverFinancialMovementWriteData data,
  }) async {
    operations?.add('add_movement');
    lastWriteData = data;
    if (addError != null) throw addError!;
    return addedMovement ?? _movementModel();
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final List<String>? operations;
  final Result<void> result;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({
    this.operations,
    this.result = const Success<void>(null),
  });

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    logs.add(data);
    return result;
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
