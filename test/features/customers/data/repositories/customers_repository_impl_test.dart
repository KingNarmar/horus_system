import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/create_audit_log_usecase.dart';
import 'package:horus_system/features/customers/data/datasources/customers_remote_data_source.dart';
import 'package:horus_system/features/customers/data/models/customer_model.dart';
import 'package:horus_system/features/customers/data/repositories/customers_repository_impl.dart';
import 'package:horus_system/features/customers/domain/entities/customer.dart';
import 'package:horus_system/features/customers/domain/entities/customer_write_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CustomersRepositoryImpl', () {
    test('forwards company scope when loading customers', () async {
      final remoteDataSource = _FakeCustomersRemoteDataSource();
      final repository = _repository(remoteDataSource);

      final result = await repository.getCustomers(companyId: _companyId);

      expect(result, isA<Success<List<Customer>>>());
      expect(remoteDataSource.lastListCompanyId, _companyId);
    });

    test('sanitizes read PostgREST failures', () async {
      final repository = _repository(
        _FakeCustomersRemoteDataSource(readError: _postgrestException),
      );

      final result = await repository.getCustomers(companyId: _companyId);

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('keeps model mapping inside the sanitized boundary', () async {
      final repository = _repository(
        _FakeCustomersRemoteDataSource(models: [_ThrowingCustomerModel()]),
      );

      final result = await repository.getCustomers(companyId: _companyId);

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('adds customer then writes audit', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addCustomer(
        data: _writeData(name: 'New Customer'),
        actorRole: 'operations',
      );

      expect(result, isA<Success<Customer>>());
      expect(result.dataOrNull?.name, 'New Customer');
      expect(operations, ['add_customer', 'audit']);
      expect(auditRepository.logs.single.description, 'customer_created');
    });

    test(
      'updates after company-scoped old snapshot lookup and audits last',
      () async {
        final operations = <String>[];
        final remoteDataSource = _FakeCustomersRemoteDataSource(
          operations: operations,
          oldModel: _model(name: 'Old Customer'),
        );
        final auditRepository = _FakeAuditLogRepository(operations: operations);
        final repository = _repository(
          remoteDataSource,
          auditRepository: auditRepository,
        );

        final result = await repository.updateCustomer(
          customerId: _customerId,
          data: _writeData(name: 'Updated Customer'),
          actorRole: 'admin',
        );

        expect(result, isA<Success<Customer>>());
        expect(operations, ['get_customer', 'update_customer', 'audit']);
        expect(remoteDataSource.lastLookupCompanyId, _companyId);
        expect(remoteDataSource.lastLookupCustomerId, _customerId);
        expect(auditRepository.logs.single.description, 'customer_updated');
        expect(auditRepository.logs.single.oldValues?['name'], 'Old Customer');
        expect(
          auditRepository.logs.single.newValues?['name'],
          'Updated Customer',
        );
      },
    );

    test('deactivates after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
        oldModel: _model(isActive: true),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.deactivateCustomer(
        companyId: _companyId,
        customerId: _customerId,
        actorRole: 'owner',
      );

      expect(result, isA<Success<Customer>>());
      expect(result.dataOrNull?.isActive, isFalse);
      expect(operations, ['get_customer', 'deactivate_customer', 'audit']);
      expect(auditRepository.logs.single.description, 'customer_deactivated');
      expect(auditRepository.logs.single.oldValues?['is_active'], isTrue);
      expect(auditRepository.logs.single.newValues?['is_active'], isFalse);
    });

    test('reactivates after old snapshot lookup and audits last', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
        oldModel: _model(isActive: false),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.reactivateCustomer(
        companyId: _companyId,
        customerId: _customerId,
        actorRole: 'owner',
      );

      expect(result, isA<Success<Customer>>());
      expect(result.dataOrNull?.isActive, isTrue);
      expect(operations, ['get_customer', 'reactivate_customer', 'audit']);
      expect(auditRepository.logs.single.description, 'customer_reactivated');
      expect(auditRepository.logs.single.oldValues?['is_active'], isFalse);
      expect(auditRepository.logs.single.newValues?['is_active'], isTrue);
    });

    test('does not audit when mutation fails', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
        addError: Exception('mutation failed'),
      );
      final auditRepository = _FakeAuditLogRepository(operations: operations);
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addCustomer(
        data: _writeData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<Customer>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_customer']);
      expect(auditRepository.logs, isEmpty);
    });

    test('propagates audit failure after successful mutation', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
      );
      final auditRepository = _FakeAuditLogRepository(
        operations: operations,
        failure: const ValidationFailure(code: FailureCodes.serverError),
      );
      final repository = _repository(
        remoteDataSource,
        auditRepository: auditRepository,
      );

      final result = await repository.addCustomer(
        data: _writeData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<Customer>>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(operations, ['add_customer', 'audit']);
    });
  });
}

const _companyId = 'company-1';
const _customerId = 'customer-1';

const _postgrestException = PostgrestException(
  message: 'secret backend message',
  code: 'XX999',
  details: 'private database details',
  hint: 'internal database hint',
);

CustomersRepositoryImpl _repository(
  CustomersRemoteDataSource remoteDataSource, {
  _FakeAuditLogRepository? auditRepository,
}) {
  return CustomersRepositoryImpl(
    remoteDataSource: remoteDataSource,
    createAuditLogUseCase: CreateAuditLogUseCase(
      auditRepository ?? _FakeAuditLogRepository(),
    ),
  );
}

CustomerWriteData _writeData({String name = 'Customer One'}) {
  return CustomerWriteData(
    companyId: _companyId,
    name: name,
    contactPerson: 'Contact',
    phone: '123',
    email: 'customer@example.com',
    taxRegistrationNumber: 'TRN',
    address: 'Address',
    city: 'Dubai',
    country: 'AE',
    creditLimit: 1000,
  );
}

CustomerModel _model({String name = 'Customer One', bool isActive = true}) {
  return CustomerModel(
    id: _customerId,
    companyId: _companyId,
    name: name,
    contactPerson: 'Contact',
    phone: '123',
    email: 'customer@example.com',
    taxRegistrationNumber: 'TRN',
    address: 'Address',
    city: 'Dubai',
    country: 'AE',
    creditLimit: 1000,
    isActive: isActive,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 2),
  );
}

class _FakeCustomersRemoteDataSource implements CustomersRemoteDataSource {
  final List<String>? operations;
  final List<CustomerModel> models;
  final Object? readError;
  final Object? addError;
  final CustomerModel oldModel;
  String? lastListCompanyId;
  String? lastLookupCompanyId;
  String? lastLookupCustomerId;

  _FakeCustomersRemoteDataSource({
    this.operations,
    List<CustomerModel>? models,
    this.readError,
    this.addError,
    CustomerModel? oldModel,
  }) : models = models ?? [_model()],
       oldModel = oldModel ?? _model(name: 'Old Customer');

  @override
  Future<List<CustomerModel>> getCustomers({required String companyId}) async {
    operations?.add('get_customers');
    lastListCompanyId = companyId;
    final error = readError;
    if (error != null) throw error;
    return models;
  }

  @override
  Future<CustomerModel> getCustomerById({
    required String companyId,
    required String customerId,
  }) async {
    operations?.add('get_customer');
    lastLookupCompanyId = companyId;
    lastLookupCustomerId = customerId;
    return oldModel;
  }

  @override
  Future<CustomerModel> addCustomer({required CustomerWriteData data}) async {
    operations?.add('add_customer');
    if (addError != null) throw addError!;
    return _model(name: data.name);
  }

  @override
  Future<CustomerModel> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
  }) async {
    operations?.add('update_customer');
    return _model(name: data.name);
  }

  @override
  Future<CustomerModel> deactivateCustomer({
    required String companyId,
    required String customerId,
  }) async {
    operations?.add('deactivate_customer');
    return _model(isActive: false);
  }

  @override
  Future<CustomerModel> reactivateCustomer({
    required String companyId,
    required String customerId,
  }) async {
    operations?.add('reactivate_customer');
    return _model(isActive: true);
  }
}

class _ThrowingCustomerModel extends CustomerModel {
  _ThrowingCustomerModel()
    : super(id: _customerId, companyId: _companyId, name: 'Customer');

  @override
  String get id => throw StateError('secret model mapping detail');
}

class _FakeAuditLogRepository implements AuditLogRepository {
  final Failure? failure;
  final List<String>? operations;
  final List<AuditLogWriteData> logs = [];

  _FakeAuditLogRepository({this.failure, this.operations});

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    operations?.add('audit');
    if (failure != null) return FailureResult<void>(failure!);
    logs.add(data);
    return const Success<void>(null);
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
