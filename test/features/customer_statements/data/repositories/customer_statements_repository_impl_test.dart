import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/customer_statements/data/constants/customer_statements_db_constants.dart';
import 'package:horus_system/features/customer_statements/data/datasources/customer_statements_remote_data_source.dart';
import 'package:horus_system/features/customer_statements/data/models/customer_statement_source_model.dart';
import 'package:horus_system/features/customer_statements/data/repositories/customer_statements_repository_impl.dart';
import 'package:horus_system/features/customer_statements/domain/failures/customer_statement_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('delegates exact company customer and date scope', () async {
    final source = _FakeRemoteDataSource(model: _model());
    final repository = CustomerStatementsRepositoryImpl(source);

    final result = await repository.getStatementSource(
      companyId: 'company-1',
      customerId: 'customer-1',
      fromDate: DateTime(2026, 8, 1),
      toDate: DateTime(2026, 8, 31),
    );

    expect(result, isA<Success>());
    expect(result.dataOrNull?.companyId, 'company-1');
    expect(source.companyId, 'company-1');
    expect(source.customerId, 'customer-1');
    expect(source.fromDate, DateTime(2026, 8, 1));
    expect(source.toDate, DateTime(2026, 8, 31));
  });

  test('maps RPC permission failure to domain permission code', () async {
    final repository = CustomerStatementsRepositoryImpl(
      _FakeRemoteDataSource(
        error: const PostgrestException(
          message: 'denied',
          code: CustomerStatementsRpcErrorCodes.permissionDenied,
        ),
      ),
    );

    final result = await repository.getStatementSource(
      companyId: 'company-1',
      customerId: 'customer-1',
    );

    expect(
      result.failureOrNull?.code,
      CustomerStatementFailureCodes.permissionView,
    );
  });

  test('maps malformed RPC payload to sanitized server failure', () async {
    final repository = CustomerStatementsRepositoryImpl(
      _FakeRemoteDataSource(formatError: true),
    );

    final result = await repository.getStatementSource(
      companyId: 'company-1',
      customerId: 'customer-1',
    );

    expect(result.failureOrNull?.code, 'server_error');
    expect(result.failureOrNull?.message, isNull);
  });
}

CustomerStatementSourceModel _model() {
  return const CustomerStatementSourceModel(
    companyId: 'company-1',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    customerId: 'customer-1',
    customerName: 'Customer',
    customerIsActive: true,
    fromDate: null,
    toDate: null,
    openingInvoices: [],
    openingPayments: [],
    movements: [],
  );
}

final class _FakeRemoteDataSource implements CustomerStatementsRemoteDataSource {
  final CustomerStatementSourceModel? model;
  final PostgrestException? error;
  final bool formatError;

  String? companyId;
  String? customerId;
  DateTime? fromDate;
  DateTime? toDate;

  _FakeRemoteDataSource({this.model, this.error, this.formatError = false});

  @override
  Future<CustomerStatementSourceModel> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    this.companyId = companyId;
    this.customerId = customerId;
    this.fromDate = fromDate;
    this.toDate = toDate;
    if (error != null) throw error!;
    if (formatError) throw const FormatException('bad payload');
    return model ?? _model();
  }
}
