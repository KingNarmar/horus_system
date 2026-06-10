import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/customer_write_data.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';

abstract class CustomersRemoteDataSource {
  Future<List<CustomerModel>> getCustomers({required String companyId});

  Future<CustomerModel> addCustomer({required CustomerWriteData data});

  Future<CustomerModel> updateCustomer({
    required String customerId,
    required CustomerWriteData data,
  });

  Future<CustomerModel> deactivateCustomer({
    required String companyId,
    required String customerId,
  });
}

class SupabaseCustomersRemoteDataSource implements CustomersRemoteDataSource {
  static const String columns =
      'id,company_id,name,contact_person,phone,email,tax_registration_number,address,city,country,credit_limit,is_active,created_at,updated_at';

  final SupabaseClient client;

  const SupabaseCustomersRemoteDataSource(this.client);

  @override
  Future<List<CustomerModel>> getCustomers({required String companyId}) async {
    final response = await client
        .from('customers')
        .select(columns)
        .eq('company_id', companyId)
        .order('name');

    return response
        .map((item) => CustomerModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<CustomerModel> addCustomer({required CustomerWriteData data}) async {
    final response = await client
        .from('customers')
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
        .from('customers')
        .update(data.toUpdateMap())
        .eq('id', customerId)
        .eq('company_id', data.companyId)
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
        .from('customers')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', customerId)
        .eq('company_id', companyId)
        .select(columns)
        .single();

    return CustomerModel.fromMap(Map<String, dynamic>.from(response));
  }
}
