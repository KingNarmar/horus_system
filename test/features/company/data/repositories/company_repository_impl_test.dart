import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/data/datasources/company_remote_data_source.dart';
import 'package:horus_system/features/company/data/models/company_model.dart';
import 'package:horus_system/features/company/data/repositories/company_repository_impl.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/company/domain/value_objects/company_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('CompanyRepositoryImpl', () {
    test(
      'createCompany forwards exact arguments and maps Domain entity',
      () async {
        final dataSource = _FakeCompanyRemoteDataSource(
          createModel: const CompanyModel(
            id: 'company-1',
            name: 'Horus Transport',
            businessType: 'Heavy Transport',
            phone: '+971500000000',
            email: 'ops@example.com',
            country: 'AE',
            city: 'Dubai',
            logoUrl: 'logo.png',
            baseCurrencyCode: 'AED',
            baseCurrencyFractionDigits: 2,
            businessTimezone: 'Asia/Dubai',
            isActive: false,
          ),
        );
        final repository = CompanyRepositoryImpl(dataSource);

        final result = await repository.createCompany(
          name: 'Horus Transport',
          businessTimezone: CompanyTimezone.tryParse('Asia/Dubai')!,
          businessType: 'Heavy Transport',
          phone: '+971500000000',
          email: 'ops@example.com',
          country: 'AE',
          city: 'Dubai',
        );

        expect(result.failureOrNull, isNull);
        expect(dataSource.createName, 'Horus Transport');
        expect(dataSource.createBusinessTimezone, 'Asia/Dubai');
        expect(dataSource.createBusinessType, 'Heavy Transport');
        expect(dataSource.createPhone, '+971500000000');
        expect(dataSource.createEmail, 'ops@example.com');
        expect(dataSource.createCountry, 'AE');
        expect(dataSource.createCity, 'Dubai');
        expect(result.dataOrNull?.id, 'company-1');
        expect(result.dataOrNull?.name, 'Horus Transport');
        expect(result.dataOrNull?.logoUrl, 'logo.png');
        expect(result.dataOrNull?.baseCurrencyCode, 'AED');
        expect(result.dataOrNull?.baseCurrencyFractionDigits, 2);
        expect(result.dataOrNull?.businessTimezone, 'Asia/Dubai');
        expect(result.dataOrNull?.isActive, isFalse);
      },
    );

    test(
      'getMyCompanies preserves datasource order and maps entities',
      () async {
        final dataSource = _FakeCompanyRemoteDataSource(
          listModels: const [
            CompanyModel(id: 'company-2', name: 'Second Company'),
            CompanyModel(id: 'company-1', name: 'First Company'),
          ],
        );
        final repository = CompanyRepositoryImpl(dataSource);

        final result = await repository.getMyCompanies();

        expect(result.failureOrNull, isNull);
        expect(dataSource.listCallCount, 1);
        expect(result.dataOrNull?.map((company) => company.id).toList(), [
          'company-2',
          'company-1',
        ]);
        expect(result.dataOrNull?.map((company) => company.name).toList(), [
          'Second Company',
          'First Company',
        ]);
      },
    );

    test('maps auth failures through sanitized repository boundary', () async {
      final repository = CompanyRepositoryImpl(
        _FakeCompanyRemoteDataSource(
          createError: AuthException('secret authentication detail'),
        ),
      );

      final result = await repository.createCompany(
        name: 'Company',
        businessTimezone: CompanyTimezone.tryParse('Asia/Dubai')!,
      );

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps persistence failures through sanitized boundary', () async {
      final repository = CompanyRepositoryImpl(
        _FakeCompanyRemoteDataSource(
          listError: const PostgrestException(
            message: 'secret backend message',
            code: 'XX999',
            details: 'private database details',
            hint: 'internal database hint',
          ),
        ),
      );

      final result = await repository.getMyCompanies();

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected create failure without internal text', () async {
      final repository = CompanyRepositoryImpl(
        _FakeCompanyRemoteDataSource(
          createError: StateError('secret create implementation detail'),
        ),
      );

      final result = await repository.createCompany(
        name: 'Company',
        businessTimezone: CompanyTimezone.tryParse('Asia/Dubai')!,
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected list failure without internal text', () async {
      final repository = CompanyRepositoryImpl(
        _FakeCompanyRemoteDataSource(
          listError: StateError('secret list implementation detail'),
        ),
      );

      final result = await repository.getMyCompanies();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

final class _FakeCompanyRemoteDataSource implements CompanyRemoteDataSource {
  final CompanyModel createModel;
  final List<CompanyModel> listModels;
  final Object? createError;
  final Object? listError;

  String? createName;
  String? createBusinessTimezone;
  String? createBusinessType;
  String? createPhone;
  String? createEmail;
  String? createCountry;
  String? createCity;
  int listCallCount = 0;

  _FakeCompanyRemoteDataSource({
    CompanyModel? createModel,
    this.listModels = const [],
    this.createError,
    this.listError,
  }) : createModel =
           createModel ?? const CompanyModel(id: 'company-1', name: 'Company');

  @override
  Future<CompanyModel> createCompany({
    required String name,
    required String businessTimezone,
    String? businessType,
    String? phone,
    String? email,
    String? country,
    String? city,
  }) async {
    createName = name;
    createBusinessTimezone = businessTimezone;
    createBusinessType = businessType;
    createPhone = phone;
    createEmail = email;
    createCountry = country;
    createCity = city;

    final error = createError;
    if (error != null) throw error;
    return createModel;
  }

  @override
  Future<List<CompanyModel>> getMyCompanies() async {
    listCallCount += 1;
    final error = listError;
    if (error != null) throw error;
    return listModels;
  }
}
