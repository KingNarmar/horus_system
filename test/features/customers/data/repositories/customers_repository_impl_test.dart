import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
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

    test('adds customer through the scoped data source', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addCustomer(
        data: _writeData(name: 'New Customer'),
        actorRole: 'operations',
      );

      expect(result, isA<Success<Customer>>());
      expect(result.dataOrNull?.name, 'New Customer');
      expect(operations, ['add_customer']);
    });

    test('updates customer without redundant audit snapshot lookup', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.updateCustomer(
        customerId: _customerId,
        data: _writeData(name: 'Updated Customer'),
        actorRole: 'admin',
      );

      expect(result, isA<Success<Customer>>());
      expect(result.dataOrNull?.name, 'Updated Customer');
      expect(operations, ['update_customer']);
      expect(remoteDataSource.lastLookupCompanyId, isNull);
      expect(remoteDataSource.lastLookupCustomerId, isNull);
    });

    test(
      'deactivates customer without redundant audit snapshot lookup',
      () async {
        final operations = <String>[];
        final remoteDataSource = _FakeCustomersRemoteDataSource(
          operations: operations,
        );
        final repository = _repository(remoteDataSource);

        final result = await repository.deactivateCustomer(
          companyId: _companyId,
          customerId: _customerId,
          actorRole: 'owner',
        );

        expect(result, isA<Success<Customer>>());
        expect(result.dataOrNull?.isActive, isFalse);
        expect(operations, ['deactivate_customer']);
      },
    );

    test(
      'reactivates customer without redundant audit snapshot lookup',
      () async {
        final operations = <String>[];
        final remoteDataSource = _FakeCustomersRemoteDataSource(
          operations: operations,
        );
        final repository = _repository(remoteDataSource);

        final result = await repository.reactivateCustomer(
          companyId: _companyId,
          customerId: _customerId,
          actorRole: 'owner',
        );

        expect(result, isA<Success<Customer>>());
        expect(result.dataOrNull?.isActive, isTrue);
        expect(operations, ['reactivate_customer']);
      },
    );

    test('sanitizes mutation failure', () async {
      final operations = <String>[];
      final remoteDataSource = _FakeCustomersRemoteDataSource(
        operations: operations,
        addError: Exception('mutation failed'),
      );
      final repository = _repository(remoteDataSource);

      final result = await repository.addCustomer(
        data: _writeData(),
        actorRole: 'operations',
      );

      expect(result, isA<FailureResult<Customer>>());
      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
      expect(result.failureOrNull?.message, isNull);
      expect(operations, ['add_customer']);
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
  CustomersRemoteDataSource remoteDataSource,
) {
  return CustomersRepositoryImpl(remoteDataSource: remoteDataSource);
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
