import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/customer_write_data.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../constants/customer_db_fields.dart';

abstract class CustomersRemoteDataSource {
  Future<List<CustomerModel>> getCustomers({required String companyId});

  Future<CustomerModel> getCustomerById({
    required String companyId,
    required String customerId,
  });

  Future<CustomerModel> addCustomer({required CustomerWriteData data});

  Future<CustomerModel> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
  });

  Future<CustomerModel> deactivateCustomer({
    required String companyId,
    required String customerId,
  });

  Future<CustomerModel> reactivateCustomer({
    required String companyId,
    required String customerId,
  });
}

class SupabaseCustomersRemoteDataSource implements CustomersRemoteDataSource {
  static const String columns = CustomerDbFields.allColumns;

  final SupabaseClient client;

  const SupabaseCustomersRemoteDataSource(this.client);

  @override
  Future<List<CustomerModel>> getCustomers({required String companyId}) async {
    final response = await client
        .from(CustomerDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .order(CustomerDbFields.name);

    return response
        .map((item) => CustomerModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<CustomerModel> getCustomerById({
    required String companyId,
    required String customerId,
  }) async {
    final response = await client
        .from(CustomerDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.id, customerId)
        .eq(DbCommonFields.companyId, companyId)
        .single();

    return CustomerModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<CustomerModel> addCustomer({required CustomerWriteData data}) async {
    final response = await client
        .from(CustomerDbFields.tableName)
        .insert(data.toInsertMap())
        .select(columns)
        .single();

    return CustomerModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<CustomerModel> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
  }) async {
    final response = await client
        .from(CustomerDbFields.tableName)
        .update(data.toUpdateMap())
        .eq(DbCommonFields.id, customerId)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(columns)
        .single();

    return CustomerModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<CustomerModel> deactivateCustomer({
    required String companyId,
    required String customerId,
  }) async {
    final response = await client
        .from(CustomerDbFields.tableName)
        .update({
          DbCommonFields.isActive: false,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.id, customerId)
        .eq(DbCommonFields.companyId, companyId)
        .select(columns)
        .single();

    return CustomerModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<CustomerModel> reactivateCustomer({
    required String companyId,
    required String customerId,
  }) async {
    final response = await client
        .from(CustomerDbFields.tableName)
        .update({
          DbCommonFields.isActive: true,
          DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
        })
        .eq(DbCommonFields.id, customerId)
        .eq(DbCommonFields.companyId, companyId)
        .select(columns)
        .single();

    return CustomerModel.fromMap(Map<String, dynamic>.from(response));
  }
}
