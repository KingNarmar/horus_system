import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../constants/payments_db_constants.dart';
import '../models/payment_model.dart';

abstract interface class PaymentsRemoteDataSource {
  Future<List<PaymentModel>> getPayments({required String companyId});

  Future<List<PaymentModel>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  });

  Future<PaymentModel> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  });
}

final class SupabasePaymentsRemoteDataSource
    implements PaymentsRemoteDataSource {
  final SupabaseClient _client;

  const SupabasePaymentsRemoteDataSource(this._client);

  @override
  Future<List<PaymentModel>> getPayments({required String companyId}) async {
    final response = await _client
        .from(PaymentsDbConstants.table)
        .select()
        .eq(DbCommonFields.companyId, companyId)
        .order(DbCommonFields.createdAt, ascending: false);

    return response
        .map((row) => PaymentModel.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<List<PaymentModel>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  }) async {
    final response = await _client
        .from(PaymentsDbConstants.table)
        .select()
        .eq(DbCommonFields.companyId, companyId)
        .eq(PaymentsDbConstants.invoiceId, invoiceId)
        .order(DbCommonFields.createdAt, ascending: false);

    return response
        .map((row) => PaymentModel.fromMap(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  @override
  Future<PaymentModel> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  }) async {
    final response = await _client.rpc(
      PaymentsDbConstants.registerPaymentRpc,
      params: {
        PaymentsDbConstants.companyIdParam: companyId,
        PaymentsDbConstants.invoiceIdParam: invoiceId,
        PaymentsDbConstants.paymentMethodIdParam: paymentMethodId,
        PaymentsDbConstants.paymentDateParam: _dateValue(paymentDate),
        PaymentsDbConstants.amountMinorUnitsParam: amount.minorUnits,
        PaymentsDbConstants.currencyCodeParam: amount.currency.value,
        PaymentsDbConstants.referenceNumberParam: referenceNumber,
        PaymentsDbConstants.notesParam: notes,
      },
    );

    return PaymentModel.fromMap(_singleMap(response));
  }
}

Map<String, dynamic> _singleMap(Object? response) {
  if (response is Map) {
    return Map<String, dynamic>.from(response);
  }
  if (response is List && response.length == 1 && response.single is Map) {
    return Map<String, dynamic>.from(response.single as Map);
  }
  throw const FormatException('Invalid register payment response.');
}

String _dateValue(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
