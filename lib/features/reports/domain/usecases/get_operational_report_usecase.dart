import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../entities/operational_trip_report.dart';
import '../failures/reports_failure_codes.dart';
import '../policies/reports_permission_policy.dart';
import '../repositories/reports_repository.dart';
import '../services/operational_report_aggregator.dart';
import '../services/report_source_integrity.dart';
import '../services/reports_context_validator.dart';
import 'report_params.dart';

final class GetOperationalReportUseCase
    implements UseCase<OperationalTripReport, OperationalReportParams> {
  final ReportsRepository _repository;
  final OperationalReportAggregator _aggregator;

  const GetOperationalReportUseCase({
    required ReportsRepository repository,
    OperationalReportAggregator aggregator =
        const OperationalReportAggregator(),
  }) : _repository = repository,
       _aggregator = aggregator;

  @override
  Future<Result<OperationalTripReport>> call(
    OperationalReportParams params,
  ) async {
    final context = params.currentCompanyContext;
    if (!ReportsPermissionPolicy.canViewOperationalReports(context.role)) {
      return const FailureResult(
        PermissionFailure(
          code: ReportsFailureCodes.permissionOperationalView,
        ),
      );
    }

    final dateFailure = ReportsContextValidator.validateDateRange(
      params.dateRange,
    );
    if (dateFailure != null) return FailureResult(dateFailure);

    final request = ReportsContextValidator.tryBuild(
      context: context,
      range: params.dateRange,
    );
    if (request == null) {
      return FailureResult(ReportsContextValidator.regionalSettingsFailure());
    }

    final result = await _repository.getOperationalTripSource(
      companyId: request.companyId,
      fromDate: request.fromDate,
      toDate: request.toDate,
    );

    return result.when(
      success: (source) {
        final metadataFailure = ReportSourceIntegrity.validateMetadata(
          metadata: source.metadata,
          expectedCompanyId: request.companyId,
          expectedCurrency: request.currency,
          expectedFractionDigits: request.fractionDigits,
          expectedBusinessTimezone: request.businessTimezone,
          expectedFromDate: request.fromDate,
          expectedToDate: request.toDate,
        );
        if (metadataFailure != null) {
          return FailureResult<OperationalTripReport>(metadataFailure);
        }

        if (!_hasValidRows(source.rows)) {
          return const FailureResult<OperationalTripReport>(
            ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
          );
        }

        return Success(
          OperationalTripReport(
            metadata: source.metadata,
            dimension: params.dimension,
            groups: _aggregator.group(
              rows: source.rows,
              dimension: params.dimension,
            ),
          ),
        );
      },
      failure: (failure) => FailureResult<OperationalTripReport>(failure),
    );
  }

  bool _hasValidRows(List<OperationalTripReportRow> rows) {
    final ids = <String>{};
    for (final row in rows) {
      if (row.tripId.trim().isEmpty ||
          !ids.add(row.tripId) ||
          row.customerId.trim().isEmpty ||
          row.customerName.trim().isEmpty ||
          row.routeId.trim().isEmpty ||
          row.loadingLocation.trim().isEmpty ||
          row.unloadingLocation.trim().isEmpty ||
          (row.quantityTons != null && row.quantityTons! < 0)) {
        return false;
      }
    }
    return true;
  }
}
