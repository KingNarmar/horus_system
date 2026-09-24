import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_write_data.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_data_source.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';
import 'customer_repository_failure_mapper.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource remoteDataSource;
  final CustomerRepositoryFailureMapper _failureMapper;

  const CustomersRepositoryImpl({required this.remoteDataSource})
    : _failureMapper = const CustomerRepositoryFailureMapper();

  @override
  Future<Result<List<Customer>>> getCustomers({required String companyId}) {
    return _guard(() async {
      final models = await remoteDataSource.getCustomers(companyId: companyId);
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addCustomer(data: data);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.updateCustomer(
        customerId: customerId,
        data: data,
      );
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
  }) {
    return _changeStatus(
      companyId: companyId,
      customerId: customerId,
      mutate: remoteDataSource.deactivateCustomer,
    );
  }

  @override
  Future<Result<Customer>> reactivateCustomer({
    required String companyId,
    required String customerId,
  }) {
    return _changeStatus(
      companyId: companyId,
      customerId: customerId,
      mutate: remoteDataSource.reactivateCustomer,
    );
  }

  Future<Result<Customer>> _changeStatus({
    required String companyId,
    required String customerId,
    required Future<CustomerModel> Function({
      required String companyId,
      required String customerId,
    })
    mutate,
  }) {
    return _guard(() async {
      final model = await mutate(companyId: companyId, customerId: customerId);
      return Success(model.toEntity());
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
