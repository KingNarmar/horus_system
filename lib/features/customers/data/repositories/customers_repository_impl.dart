import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_write_data.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_data_source.dart';
import '../mappers/customer_mapper.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource remoteDataSource;

  const CustomersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Customer>>> getCustomers({required String companyId}) async {
    try {
      final normalizedCompanyId = companyId.trim();

      if (normalizedCompanyId.isEmpty) {
        return const FailureResult<List<Customer>>(
          ValidationFailure(message: 'Company id is required.'),
        );
      }

      final models = await remoteDataSource.getCustomers(
        companyId: normalizedCompanyId,
      );

      return Success(models.map((model) => model.toEntity()).toList());
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(message: error.message, code: error.code),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<Customer>> addCustomer({required CustomerWriteData data}) async {
    try {
      final model = await remoteDataSource.addCustomer(data: data);
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(message: error.message, code: error.code),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
  }) async {
    try {
      final model = await remoteDataSource.updateCustomer(
        customerId: customerId,
        data: data,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(message: error.message, code: error.code),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }

  @override
  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
  }) async {
    try {
      final model = await remoteDataSource.deactivateCustomer(
        companyId: companyId,
        customerId: customerId,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      return FailureResult(
        ServerFailure(message: error.message, code: error.code),
      );
    } catch (error) {
      return FailureResult(UnexpectedFailure(message: error.toString()));
    }
  }
}
