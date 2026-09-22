import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../../company/domain/policies/company_financial_readiness_policy.dart';
import '../entities/billable_trip.dart';
import '../entities/invoice_totals.dart';
import '../policies/invoice_trip_eligibility_policy.dart';
import '../services/invoice_totals_calculator.dart';

final class CalculateInvoiceDraftPreviewParams {
  final CurrentCompanyContext currentCompanyContext;
  final String customerId;
  final List<BillableTrip> trips;
  final int discountMinorUnits;
  final int taxRateBasisPoints;

  CalculateInvoiceDraftPreviewParams({
    required this.currentCompanyContext,
    required this.customerId,
    required List<BillableTrip> trips,
    this.discountMinorUnits = 0,
    this.taxRateBasisPoints = 0,
  }) : trips = List.unmodifiable(trips);
}

final class CalculateInvoiceDraftPreviewUseCase
    implements UseCase<InvoiceTotals, CalculateInvoiceDraftPreviewParams> {
  final InvoiceTotalsCalculator _totalsCalculator;

  const CalculateInvoiceDraftPreviewUseCase({
    InvoiceTotalsCalculator totalsCalculator = const InvoiceTotalsCalculator(),
  }) : _totalsCalculator = totalsCalculator;

  @override
  Future<Result<InvoiceTotals>> call(
    CalculateInvoiceDraftPreviewParams params,
  ) async {
    final customerId = params.customerId.trim();
    if (customerId.isEmpty) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(code: FailureCodes.validationInvoiceCustomerRequired),
      );
    }

    if (params.trips.isEmpty) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(code: FailureCodes.validationInvoiceTripsRequired),
      );
    }

    final tripIds = params.trips.map((trip) => trip.id).toList(growable: false);
    if (tripIds.toSet().length != tripIds.length) {
      return const FailureResult<InvoiceTotals>(
        ValidationFailure(code: FailureCodes.validationInvoiceDuplicateTrip),
      );
    }

    final readiness = CompanyFinancialReadinessPolicy.evaluate(
      params.currentCompanyContext.company,
    );
    final configuration = readiness.configuration;
    if (!readiness.isReady || configuration == null) {
      return const FailureResult<InvoiceTotals>(
        ConflictFailure(
          code: CompanyFailureCodes.conflictFinancialSettingsNotConfigured,
        ),
      );
    }

    for (final trip in params.trips) {
      final eligibilityFailure = InvoiceTripEligibilityPolicy.validate(
        trip: trip,
        companyId: params.currentCompanyContext.companyId,
        customerId: customerId,
        currency: configuration.baseCurrency,
      );
      if (eligibilityFailure != null) {
        return FailureResult<InvoiceTotals>(eligibilityFailure);
      }
    }

    return _totalsCalculator.calculate(
      lineAmounts: params.trips
          .map((trip) => trip.freightAmount)
          .toList(growable: false),
      currency: configuration.baseCurrency,
      discountMinorUnits: params.discountMinorUnits,
      taxRateBasisPoints: params.taxRateBasisPoints,
    );
  }
}
