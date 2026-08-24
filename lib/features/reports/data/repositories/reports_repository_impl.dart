import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/open_invoices_report.dart';
import '../../domain/entities/operational_trip_report.dart';
import '../../domain/entities/trip_expenses_report.dart';
import '../../domain/entities/trip_net_profit_report.dart';
import '../../domain/failures/reports_failure_codes.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_data_source.dart';
import '../mappers/report_source_mappers.dart';
import 'reports_repository_failure_mapper.dart';

final class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _remoteDataSource;

  const ReportsRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = ReportsRepositoryFailureMapper();

  @override
  Future<Result<OperationalTripReportSource>> getOperationalTripSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    return _guard(
      () async => (await _remoteDataSource.getOperationalSource(
        companyId: companyId,
        fromDate: fromDate,
        toDate: toDate,
      )).toEntity(),
      permissionFailureCode: ReportsFailureCodes.permissionOperationalView,
    );
  }

  @override
  Future<Result<TripExpensesReportSource>> getTripExpensesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    return _guard(
      () async => (await _remoteDataSource.getTripExpensesSource(
        companyId: companyId,
        fromDate: fromDate,
        toDate: toDate,
      )).toEntity(),
      permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
    );
  }

  @override
  Future<Result<TripNetProfitReportSource>> getTripNetProfitSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    return _guard(
      () async => (await _remoteDataSource.getTripNetProfitSource(
        companyId: companyId,
        fromDate: fromDate,
        toDate: toDate,
      )).toEntity(),
      permissionFailureCode: ReportsFailureCodes.permissionFinancialView,
    );
  }

  @override
  Future<Result<OpenInvoicesReportSource>> getOpenInvoicesSource({
    required String companyId,
    required DateTime? fromDate,
    required DateTime? toDate,
  }) {
    return _guard(
      () async => (await _remoteDataSource.getOpenInvoicesSource(
        companyId: companyId,
        fromDate: fromDate,
        toDate: toDate,
      )).toEntity(),
      permissionFailureCode: ReportsFailureCodes.permissionOpenInvoicesView,
    );
  }

  Future<Result<T>> _guard<T>(
    Future<T> Function() action, {
    required String permissionFailureCode,
  }) async {
    try {
      return Success(await action());
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } on PostgrestException catch (error) {
      return FailureResult(
        _failureMapper.fromPostgrest(
          error,
          permissionFailureCode: permissionFailureCode,
        ),
      );
    } on FormatException catch (error) {
      return FailureResult(_failureMapper.fromFormatException(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
