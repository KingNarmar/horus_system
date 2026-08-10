import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/payment_method_write_data.dart';
import '../constants/payment_method_db_fields.dart';
import '../mappers/payment_method_mapper.dart';
import '../models/payment_method_model.dart';

abstract interface class PaymentMethodsRemoteDataSource {
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String companyId,
  });

  Future<List<PaymentMethodModel>> getActivePaymentMethods({
    required String companyId,
  });

  Future<PaymentMethodModel> getPaymentMethodById({
    required String companyId,
    required String paymentMethodId,
  });

  Future<PaymentMethodModel> addPaymentMethod({
    required PaymentMethodWriteData data,
  });

  Future<PaymentMethodModel> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
  });

  Future<PaymentMethodModel> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  });

  Future<PaymentMethodModel> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  });
}

class SupabasePaymentMethodsRemoteDataSource
    implements PaymentMethodsRemoteDataSource {
  static const String columns = PaymentMethodDbFields.allColumns;

  final SupabaseClient client;

  const SupabasePaymentMethodsRemoteDataSource(this.client);

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods({
    required String companyId,
  }) async {
    final response = await client
        .from(PaymentMethodDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .order(PaymentMethodDbFields.name);

    return _modelsFromResponse(response);
  }

  @override
  Future<List<PaymentMethodModel>> getActivePaymentMethods({
    required String companyId,
  }) async {
    final response = await client
        .from(PaymentMethodDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.companyId, companyId)
        .eq(DbCommonFields.isActive, true)
        .order(PaymentMethodDbFields.name);

    return _modelsFromResponse(response);
  }

  @override
  Future<PaymentMethodModel> getPaymentMethodById({
    required String companyId,
    required String paymentMethodId,
  }) async {
    final response = await client
        .from(PaymentMethodDbFields.tableName)
        .select(columns)
        .eq(DbCommonFields.id, paymentMethodId)
        .eq(DbCommonFields.companyId, companyId)
        .single();

    return PaymentMethodModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<PaymentMethodModel> addPaymentMethod({
    required PaymentMethodWriteData data,
  }) async {
    final values = data.toInsertMap();
    final actorUserId = client.auth.currentUser?.id;
    if (actorUserId != null) {
      values[DbCommonFields.createdBy] = actorUserId;
    }

    final response = await client
        .from(PaymentMethodDbFields.tableName)
        .insert(values)
        .select(columns)
        .single();

    return PaymentMethodModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<PaymentMethodModel> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
  }) async {
    final values = data.toUpdateMap();
    _addUpdatedBy(values);

    final response = await client
        .from(PaymentMethodDbFields.tableName)
        .update(values)
        .eq(DbCommonFields.id, paymentMethodId)
        .eq(DbCommonFields.companyId, data.companyId)
        .select(columns)
        .single();

    return PaymentMethodModel.fromMap(Map<String, dynamic>.from(response));
  }

  @override
  Future<PaymentMethodModel> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  }) {
    return _setActive(
      companyId: companyId,
      paymentMethodId: paymentMethodId,
      isActive: false,
    );
  }

  @override
  Future<PaymentMethodModel> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
  }) {
    return _setActive(
      companyId: companyId,
      paymentMethodId: paymentMethodId,
      isActive: true,
    );
  }

  Future<PaymentMethodModel> _setActive({
    required String companyId,
    required String paymentMethodId,
    required bool isActive,
  }) async {
    final values = <String, dynamic>{DbCommonFields.isActive: isActive};
    _addUpdatedBy(values);

    final response = await client
        .from(PaymentMethodDbFields.tableName)
        .update(values)
        .eq(DbCommonFields.id, paymentMethodId)
        .eq(DbCommonFields.companyId, companyId)
        .select(columns)
        .single();

    return PaymentMethodModel.fromMap(Map<String, dynamic>.from(response));
  }

  void _addUpdatedBy(Map<String, dynamic> values) {
    final actorUserId = client.auth.currentUser?.id;
    if (actorUserId != null) {
      values[DbCommonFields.updatedBy] = actorUserId;
    }
  }

  List<PaymentMethodModel> _modelsFromResponse(
    List<Map<String, dynamic>> response,
  ) {
    return response
        .map(
          (item) => PaymentMethodModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
