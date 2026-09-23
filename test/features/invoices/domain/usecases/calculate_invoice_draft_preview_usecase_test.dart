import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/usecases/calculate_invoice_draft_preview_usecase.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

void main() {
  const useCase = CalculateInvoiceDraftPreviewUseCase();

  test('calculates totals for grouped Trips from the same customer', () async {
    final result = await useCase(
      CalculateInvoiceDraftPreviewParams(
        currentCompanyContext: _context(),
        customerId: 'customer-1',
        trips: [
          _trip(id: 'trip-1', amountMinorUnits: 300000),
          _trip(id: 'trip-2', amountMinorUnits: 150000),
        ],
      ),
    );

    expect(result, isA<Success<InvoiceTotals>>());
    expect(result.dataOrNull!.subtotal.minorUnits, 450000);
    expect(result.dataOrNull!.grandTotal.minorUnits, 450000);
  });

  test('rejects Trips that belong to another customer', () async {
    final result = await useCase(
      CalculateInvoiceDraftPreviewParams(
        currentCompanyContext: _context(),
        customerId: 'customer-1',
        trips: [
          _trip(
            id: 'trip-2',
            customerId: 'customer-2',
            amountMinorUnits: 150000,
          ),
        ],
      ),
    );

    expect(result, isA<FailureResult<InvoiceTotals>>());
    expect(
      result.failureOrNull?.code,
      FailureCodes.conflictInvoiceTripCustomerMismatch,
    );
  });

  test('rejects duplicate Trip selection', () async {
    final trip = _trip(id: 'trip-1', amountMinorUnits: 300000);
    final result = await useCase(
      CalculateInvoiceDraftPreviewParams(
        currentCompanyContext: _context(),
        customerId: 'customer-1',
        trips: [trip, trip],
      ),
    );

    expect(result, isA<FailureResult<InvoiceTotals>>());
    expect(
      result.failureOrNull?.code,
      FailureCodes.validationInvoiceDuplicateTrip,
    );
  });

  test('rejects preview access for a viewer', () async {
    final result = await useCase(
      CalculateInvoiceDraftPreviewParams(
        currentCompanyContext: _context(role: CompanyRole.viewer),
        customerId: 'customer-1',
        trips: [_trip(id: 'trip-1', amountMinorUnits: 300000)],
      ),
    );

    expect(result, isA<FailureResult<InvoiceTotals>>());
    expect(
      result.failureOrNull?.code,
      FailureCodes.permissionInvoicesManagement,
    );
  });
}

CurrentCompanyContext _context({CompanyRole role = CompanyRole.accountant}) {
  return CurrentCompanyContext(
    company: const Company(
      id: 'company-1',
      name: 'Test Company',
      baseCurrencyCode: 'AED',
      baseCurrencyFractionDigits: 2,
    ),
    role: role,
  );
}

final CurrencyCode _currency = CurrencyCode.tryParse('AED')!;

BillableTrip _trip({
  required String id,
  required int amountMinorUnits,
  String customerId = 'customer-1',
}) {
  return BillableTrip(
    id: id,
    companyId: 'company-1',
    customerId: customerId,
    status: TripStatus.documentsReceived,
    freightAmount: Money(minorUnits: amountMinorUnits, currency: _currency),
    isAlreadyInvoiced: false,
  );
}
