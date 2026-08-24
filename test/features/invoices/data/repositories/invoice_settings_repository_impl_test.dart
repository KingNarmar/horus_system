import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/invoices/data/constants/invoices_rpc_error_codes.dart';
import 'package:horus_system/features/invoices/data/datasources/invoice_settings_remote_data_source.dart';
import 'package:horus_system/features/invoices/data/models/company_invoice_settings_model.dart';
import 'package:horus_system/features/invoices/data/repositories/invoice_settings_repository_impl.dart';
import 'package:horus_system/features/invoices/domain/failures/invoice_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_prefix.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('InvoiceSettingsRepositoryImpl', () {
    test('preserves company-scoped nullable settings read', () async {
      final dataSource = _FakeInvoiceSettingsRemoteDataSource()
        ..getModel = null;

      final result = await InvoiceSettingsRepositoryImpl(
        dataSource,
      ).get(companyId: 'company-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isNull);
      expect(dataSource.getCompanyId, 'company-1');
    });

    test('forwards settings update and maps the returned entity', () async {
      final dataSource = _FakeInvoiceSettingsRemoteDataSource()
        ..updateModel = const CompanyInvoiceSettingsModel(
          companyId: 'company-1',
          invoicePrefix: 'INV',
        );
      final prefix = InvoicePrefix.tryParse('new')!;

      final result = await InvoiceSettingsRepositoryImpl(dataSource).update(
        companyId: 'company-1',
        prefix: prefix,
      );

      expect(result.isSuccess, isTrue);
      expect(dataSource.updateCompanyId, 'company-1');
      expect(dataSource.updatePrefix, prefix);
      expect(result.dataOrNull?.companyId, 'company-1');
      expect(result.dataOrNull?.prefix.value, 'INV');
    });

    test('maps read permission failures using invoices view code', () async {
      final dataSource = _FakeInvoiceSettingsRemoteDataSource()
        ..getError = PostgrestException(
          message: 'permission denied',
          code: InvoicesRpcErrorCodes.permissionDenied,
        );

      final result = await InvoiceSettingsRepositoryImpl(
        dataSource,
      ).get(companyId: 'company-1');

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(result.failureOrNull?.code, FailureCodes.permissionInvoicesView);
    });

    test(
      'maps update permission failures using settings management code',
      () async {
        final dataSource = _FakeInvoiceSettingsRemoteDataSource()
          ..updateError = PostgrestException(
            message: 'permission denied',
            code: InvoicesRpcErrorCodes.permissionDenied,
          );
        final prefix = InvoicePrefix.tryParse('INV')!;

        final result = await InvoiceSettingsRepositoryImpl(dataSource).update(
          companyId: 'company-1',
          prefix: prefix,
        );

        expect(result.failureOrNull, isA<PermissionFailure>());
        expect(
          result.failureOrNull?.code,
          InvoiceFailureCodes.permissionSettingsManagement,
        );
      },
    );

    test(
      'maps auth exceptions to the existing auth-required failure',
      () async {
        final dataSource = _FakeInvoiceSettingsRemoteDataSource()
          ..getError = AuthException('expired');

        final result = await InvoiceSettingsRepositoryImpl(
          dataSource,
        ).get(companyId: 'company-1');

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
      },
    );

    test(
      'keeps model mapping inside the corrupt-data failure boundary',
      () async {
        final dataSource = _FakeInvoiceSettingsRemoteDataSource()
          ..getModel = const CompanyInvoiceSettingsModel(
            companyId: 'company-1',
            invoicePrefix: 'invalid prefix!',
          );

        final result = await InvoiceSettingsRepositoryImpl(
          dataSource,
        ).get(companyId: 'company-1');

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(result.failureOrNull?.code, FailureCodes.serverError);
        expect(result.failureOrNull?.message, isNull);
      },
    );

    test('maps unexpected failures without exposing internal text', () async {
      final dataSource = _FakeInvoiceSettingsRemoteDataSource()
        ..getError = StateError('secret internal text');

      final result = await InvoiceSettingsRepositoryImpl(
        dataSource,
      ).get(companyId: 'company-1');

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

final class _FakeInvoiceSettingsRemoteDataSource
    implements InvoiceSettingsRemoteDataSource {
  String? getCompanyId;
  String? updateCompanyId;
  InvoicePrefix? updatePrefix;
  Object? getError;
  Object? updateError;
  CompanyInvoiceSettingsModel? getModel = const CompanyInvoiceSettingsModel(
    companyId: 'company-1',
    invoicePrefix: 'INV',
  );
  CompanyInvoiceSettingsModel updateModel = const CompanyInvoiceSettingsModel(
    companyId: 'company-1',
    invoicePrefix: 'INV',
  );

  @override
  Future<CompanyInvoiceSettingsModel?> get({required String companyId}) async {
    getCompanyId = companyId;
    if (getError case final error?) throw error;
    return getModel;
  }

  @override
  Future<CompanyInvoiceSettingsModel> update({
    required String companyId,
    required InvoicePrefix prefix,
  }) async {
    updateCompanyId = companyId;
    updatePrefix = prefix;
    if (updateError case final error?) throw error;
    return updateModel;
  }
}
