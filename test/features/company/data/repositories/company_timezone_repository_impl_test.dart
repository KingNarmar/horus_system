import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/datasources/company_timezone_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_model.dart';
import 'package:horus_system/features/company/data/repositories/company_timezone_repository_impl.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyTimezoneRepositoryImpl', () {
    test('maps timezone catalog into pure Domain value objects', () async {
      final repository = CompanyTimezoneRepositoryImpl(
        _FakeCompanyTimezoneRemoteDataSource(
          options: const ['Asia/Dubai', 'Europe/London'],
        ),
      );

      final result = await repository.getTimezoneOptions();

      expect(result.failureOrNull, isNull);
      expect(
        result.dataOrNull?.map((option) => option.value).toList(),
        ['Asia/Dubai', 'Europe/London'],
      );
    });

    test('sanitizes malformed catalog data as a server failure', () async {
      final repository = CompanyTimezoneRepositoryImpl(
        _FakeCompanyTimezoneRemoteDataSource(
          options: const ['Asia/Dubai', 'bad timezone'],
        ),
      );

      final result = await repository.getTimezoneOptions();

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('update forwards company scope and maps the returned company', () async {
      final dataSource = _FakeCompanyTimezoneRemoteDataSource(
        updateModel: const CompanyModel(
          id: 'company-1',
          name: 'Horus Transport',
          businessTimezone: 'Europe/London',
        ),
      );
      final repository = CompanyTimezoneRepositoryImpl(dataSource);

      final result = await repository.updateBusinessTimezone(
        companyId: 'company-1',
        businessTimezone: CompanyTimezone.tryParse('Europe/London')!,
      );

      expect(result.failureOrNull, isNull);
      expect(dataSource.lastCompanyId, 'company-1');
      expect(dataSource.lastTimezone, 'Europe/London');
      expect(result.dataOrNull?.businessTimezone, 'Europe/London');
    });

    test('maps database permission denial to typed settings failure', () async {
      final repository = CompanyTimezoneRepositoryImpl(
        _FakeCompanyTimezoneRemoteDataSource(
          updateError: const PostgrestException(
            message: 'permission denied',
            code: '42501',
            details: 'private details',
            hint: 'private hint',
          ),
        ),
      );

      final result = await repository.updateBusinessTimezone(
        companyId: 'company-1',
        businessTimezone: CompanyTimezone.tryParse('Asia/Dubai')!,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.permissionSettingsManagement,
      );
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

final class _FakeCompanyTimezoneRemoteDataSource
    implements CompanyTimezoneRemoteDataSource {
  final List<String> options;
  final CompanyModel updateModel;
  final Object? updateError;

  String? lastCompanyId;
  String? lastTimezone;

  _FakeCompanyTimezoneRemoteDataSource({
    this.options = const [],
    CompanyModel? updateModel,
    this.updateError,
  }) : updateModel = updateModel ??
            const CompanyModel(
              id: 'company-1',
              name: 'Horus Transport',
              businessTimezone: 'Asia/Dubai',
            );

  @override
  Future<List<String>> getTimezoneOptions() async => options;

  @override
  Future<CompanyModel> updateBusinessTimezone({
    required String companyId,
    required String businessTimezone,
  }) async {
    lastCompanyId = companyId;
    lastTimezone = businessTimezone;
    final error = updateError;
    if (error != null) throw error;
    return updateModel;
  }
}
