import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/dashboard/data/constants/dashboard_db_constants.dart';
import 'package:horus_system/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:horus_system/features/dashboard/data/models/dashboard_source_model.dart';
import 'package:horus_system/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:horus_system/features/dashboard/domain/failures/dashboard_failure_codes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('DashboardRepositoryImpl', () {
    test('preserves company scope and maps source model to Domain', () async {
      final dataSource = _FakeDashboardRemoteDataSource();
      final repository = DashboardRepositoryImpl(dataSource);

      final result = await repository.getDashboardSource(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isNull);
      expect(result.dataOrNull?.companyId, 'company-1');
      expect(result.dataOrNull?.revenue.minorUnits, 120000);
      expect(result.dataOrNull?.revenue.currency.value, 'AED');
      expect(result.dataOrNull?.businessTimezone, 'Asia/Dubai');
      expect(dataSource.lastCompanyId, 'company-1');
    });

    test('maps permission failures through repository boundary', () async {
      final repository = DashboardRepositoryImpl(
        _FakeDashboardRemoteDataSource(
          nextError: const PostgrestException(
            message: 'permission denied',
            code: DashboardRpcErrorCodes.permissionDenied,
          ),
        ),
      );

      final result = await repository.getDashboardSource(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(result.failureOrNull?.code, DashboardFailureCodes.permissionView);
      expect(result.failureOrNull?.message, isNull);
    });

    test(
      'maps auth exceptions to the existing auth-required failure',
      () async {
        final repository = DashboardRepositoryImpl(
          _FakeDashboardRemoteDataSource(nextError: AuthException('expired')),
        );

        final result = await repository.getDashboardSource(
          companyId: 'company-1',
        );

        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull?.code, CompanyFailureCodes.authRequired);
        expect(result.failureOrNull?.message, isNull);
      },
    );

    test('keeps model mapping inside corrupt-data failure boundary', () async {
      final repository = DashboardRepositoryImpl(
        _FakeDashboardRemoteDataSource(
          model: _dashboardModel(baseCurrencyCode: 'invalid'),
        ),
      );

      final result = await repository.getDashboardSource(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps datasource format failures to generic server failure', () async {
      final repository = DashboardRepositoryImpl(
        _FakeDashboardRemoteDataSource(
          nextError: const FormatException('malformed RPC response'),
        ),
      );

      final result = await repository.getDashboardSource(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps unexpected failures without exposing internal text', () async {
      final repository = DashboardRepositoryImpl(
        _FakeDashboardRemoteDataSource(
          nextError: StateError('secret internal text'),
        ),
      );

      final result = await repository.getDashboardSource(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull?.message, isNull);
    });
  });
}

DashboardSourceModel _dashboardModel({String baseCurrencyCode = 'AED'}) {
  return DashboardSourceModel(
    companyId: 'company-1',
    baseCurrencyCode: baseCurrencyCode,
    baseCurrencyFractionDigits: 2,
    businessTimezone: 'Asia/Dubai',
    businessDate: DateTime(2026, 8, 24),
    todayTrips: 1,
    runningTrips: 2,
    deliveredTrips: 3,
    availableVehicles: 4,
    vehiclesOnTrip: 5,
    unpaidInvoices: 6,
    revenueMinorUnits: 120000,
    tripExpensesMinorUnits: 45000,
    companyExpensesMinorUnits: 15000,
    financialCurrencyMismatchCount: 0,
    expensePrecisionLossCount: 0,
    negativeExpenseCount: 0,
    invalidInvoiceBalanceCount: 0,
  );
}

final class _FakeDashboardRemoteDataSource
    implements DashboardRemoteDataSource {
  final DashboardSourceModel model;
  final Object? nextError;

  String? lastCompanyId;

  _FakeDashboardRemoteDataSource({
    DashboardSourceModel? model,
    this.nextError,
  }) : model = model ?? _dashboardModel();

  @override
  Future<DashboardSourceModel> getDashboardSource({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    final error = nextError;
    if (error != null) throw error;
    return model;
  }
}
