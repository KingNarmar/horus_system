import '../../../../core/utils/result.dart';
import '../entities/customer.dart';
import '../entities/customer_write_data.dart';

abstract class CustomersRepository {
  Future<Result<List<Customer>>> getCustomers({required String companyId});

  Future<Result<Customer>> addCustomer({
    required CustomerWriteData data,
    required String actorRole,
  });

  Future<Result<Customer>> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
    required String actorRole,
  });

  Future<Result<Customer>> deactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  });

  Future<Result<Customer>> reactivateCustomer({
    required String companyId,
    required String customerId,
    required String actorRole,
  });
}
