import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/data/constants/company_rpc_error_codes.dart';
import 'package:horus_system/features/company/data/datasources/company_financial_settings_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_model.dart';
import 'package:horus_system/features/company/data/repositories/company_financial_settings_repository_impl.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyFinancialSettingsRepositoryImpl', () {
    test('keeps company scope and maps the saved company', () async {
      final dataSource = _FakeFinancialSettingsDataSource();
      final repository = CompanyFinancialSettingsRepositoryImpl(dataSource);

      final result = await repository.update(
        companyId: 'company-1',
        baseCurrencyCode: 'AED',
        baseCurrencyFractionDigits: 2,
      );

      expect(result, isA<Success<Company>>());
      expect(dataSource.calls, 1);
      expect(dataSource.companyId, 'company-1');
      expect(dataSource.baseCurrencyCode, 'AED');
      expect(dataSource.baseCurrencyFractionDigits, 2);
      expect(result.dataOrNull?.baseCurrencyCode, 'AED');
      expect(result.dataOrNull?.baseCurrencyFractionDigits, 2);
    });

    test('maps historical currency mismatch to typed conflict', () async {
      final repository = CompanyFinancialSettingsRepositoryImpl(
        _FakeFinancialSettingsDataSource(
          error: const PostgrestException(
            message: 'history mismatch',
            code: CompanyRpcErrorCodes.baseCurrencyHistoryMismatch,
          ),
        ),
      );

      final result = await repository.update(
        companyId: 'company-1',
        baseCurrencyCode: 'USD',
        baseCurrencyFractionDigits: 2,
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.conflictBaseCurrencyHistoryMismatch,
      );
    });

    test('maps authentication errors without exposing backend text', () async {
      final repository = CompanyFinancialSettingsRepositoryImpl(
        _FakeFinancialSettingsDataSource(error: AuthException('expired token')),
      );

      final result = await repository.update(
        companyId: 'company-1',
        baseCurrencyCode: 'AED',
        baseCurrencyFractionDigits: 2,
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
      expect(result.failureOrNull?.message, isNull);
    });

    test('sanitizes unexpected failures', () async {
      final repository = CompanyFinancialSettingsRepositoryImpl(
        _FakeFinancialSettingsDataSource(error: StateError('secret details')),
      );

      final result = await repository.update(
        companyId: 'company-1',
        baseCurrencyCode: 'AED',
        baseCurrencyFractionDigits: 2,
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

final class _FakeFinancialSettingsDataSource
    implements CompanyFinancialSettingsRemoteDataSource {
  final Object? error;
  int calls = 0;
  String? companyId;
  String? baseCurrencyCode;
  int? baseCurrencyFractionDigits;

  _FakeFinancialSettingsDataSource({this.error});

  @override
  Future<CompanyModel> update({
    required String companyId,
    required String baseCurrencyCode,
    required int baseCurrencyFractionDigits,
  }) async {
    calls++;
    this.companyId = companyId;
    this.baseCurrencyCode = baseCurrencyCode;
    this.baseCurrencyFractionDigits = baseCurrencyFractionDigits;

    final nextError = error;
    if (nextError != null) throw nextError;

    return CompanyModel(
      id: companyId,
      name: 'Horus Transport',
      baseCurrencyCode: baseCurrencyCode,
      baseCurrencyFractionDigits: baseCurrencyFractionDigits,
      businessTimezone: 'Asia/Dubai',
    );
  }
}
