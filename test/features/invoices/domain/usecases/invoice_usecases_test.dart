import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/company/domain/failures/company_failure_codes.dart';
import 'package:horus_system/features/invoices/domain/entities/billable_trip.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_creation_context.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/repositories/invoices_repository.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_draft_usecases.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_lifecycle_usecases.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_params.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_query_usecases.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';
import 'package:test/test.dart';

void main() {
  group('invoice query use cases', () {
    test('driver cannot view invoices', () async {
      final repository = _FakeInvoicesRepository();
      final result = await GetInvoicesUseCase(repository)(
        GetInvoicesParams(currentCompanyContext: _context(CompanyRole.driver)),
      );

      expect(result.failureOrNull?.code, FailureCodes.permissionInvoicesView);
      expect(repository.getInvoicesCalls, 0);
    });

    test('authorized reads are scoped to current company', () async {
      final repository = _FakeInvoicesRepository();
      await GetInvoicesUseCase(repository)(
        GetInvoicesParams(currentCompanyContext: _context(CompanyRole.viewer)),
      );

      expect(repository.lastCompanyId, 'company-1');
    });
  });

  group('invoice draft use cases', () {
    test('single-trip creation recalculates from repository context', () async {
      final repository = _FakeInvoicesRepository();
      final result = await CreateInvoiceFromTripUseCase(repository)(
        CreateInvoiceFromTripParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          input: InvoiceDraftInput(
            customerId: ' customer-1 ',
            tripIds: [' trip-1 '],
            currencyCode: 'aed',
          ),
        ),
      );

      expect(result, isA<Success<Invoice>>());
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastTripIds, ['trip-1']);
      expect(repository.lastActorRole, 'accountant');
      expect(repository.lastDraftData?.lines.single.tripId, 'trip-1');
    });

    test('grouped creation requires at least two trips', () async {
      final repository = _FakeInvoicesRepository();
      final result = await CreateGroupedInvoiceUseCase(repository)(
        CreateGroupedInvoiceParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          input: InvoiceDraftInput(
            customerId: 'customer-1',
            tripIds: ['trip-1'],
            currencyCode: 'AED',
          ),
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationInvoiceGroupedTripsRequired,
      );
      expect(repository.creationContextCalls, 0);
    });

    test('issued invoices cannot be edited', () async {
      final repository = _FakeInvoicesRepository()
        ..invoiceForDetails = _invoice(status: InvoiceStatus.issued);
      final result = await UpdateInvoiceDraftUseCase(repository)(
        UpdateInvoiceDraftParams(
          currentCompanyContext: _context(CompanyRole.admin),
          invoiceId: 'invoice-1',
          input: InvoiceDraftInput(
            customerId: 'customer-1',
            tripIds: ['trip-1'],
            currencyCode: 'AED',
          ),
        ),
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.conflictInvoiceIssuedImmutable,
      );
      expect(repository.updateDraftCalls, 0);
    });
  });

  group('invoice lifecycle use cases', () {
    test('future issue dates are rejected against company date', () async {
      final repository = _FakeInvoicesRepository();
      final businessDateProvider = _FixedBusinessDateProvider(
        DateTime.utc(2026, 8, 5),
      );
      final result =
          await IssueInvoiceUseCase(
            repository,
            businessDateProvider: businessDateProvider,
          )(
            IssueInvoiceParams(
              currentCompanyContext: _context(CompanyRole.owner),
              invoiceId: 'invoice-1',
              issueDate: DateTime.utc(2026, 8, 6),
              dueDate: DateTime.utc(2026, 9, 5),
            ),
          );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationInvoiceIssueDateFuture,
      );
      expect(businessDateProvider.lastCompanyId, 'company-1');
      expect(repository.issueCalls, 0);
    });

    test('missing company settings stop invoice issuance', () async {
      final repository = _FakeInvoicesRepository();
      final businessDateProvider = _FixedBusinessDateProvider.withResult(
        const FailureResult<DateTime>(
          ConflictFailure(
            code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
          ),
        ),
      );
      final result =
          await IssueInvoiceUseCase(
            repository,
            businessDateProvider: businessDateProvider,
          )(
            IssueInvoiceParams(
              currentCompanyContext: _context(CompanyRole.admin),
              invoiceId: 'invoice-1',
              issueDate: DateTime.utc(2026, 8, 5),
              dueDate: DateTime.utc(2026, 9, 4),
            ),
          );

      expect(
        result.failureOrNull?.code,
        CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
      );
      expect(repository.issueCalls, 0);
      expect(repository.creationContextCalls, 0);
    });

    test('draft invoice can be issued with company and actor scope', () async {
      final repository = _FakeInvoicesRepository();
      final businessDateProvider = _FixedBusinessDateProvider(
        DateTime.utc(2026, 8, 5),
      );
      final result =
          await IssueInvoiceUseCase(
            repository,
            businessDateProvider: businessDateProvider,
          )(
            IssueInvoiceParams(
              currentCompanyContext: _context(CompanyRole.admin),
              invoiceId: 'invoice-1',
              issueDate: DateTime.utc(2026, 8, 5),
              dueDate: DateTime.utc(2026, 9, 4),
            ),
          );

      expect(result, isA<Success<Invoice>>());
      expect(businessDateProvider.lastCompanyId, 'company-1');
      expect(repository.issueCalls, 1);
      expect(repository.lastCompanyId, 'company-1');
      expect(repository.lastActorRole, 'admin');
    });

    test('revalidates trip eligibility before issuing a draft', () async {
      final repository = _FakeInvoicesRepository()
        ..currentTripStatus = TripStatus.cancelled;
      final result =
          await IssueInvoiceUseCase(
            repository,
            businessDateProvider: _FixedBusinessDateProvider(
              DateTime.utc(2026, 8, 5),
            ),
          )(
            IssueInvoiceParams(
              currentCompanyContext: _context(CompanyRole.admin),
              invoiceId: 'invoice-1',
              issueDate: DateTime.utc(2026, 8, 5),
              dueDate: DateTime.utc(2026, 9, 4),
            ),
          );

      expect(
        result.failureOrNull?.code,
        FailureCodes.conflictInvoiceTripNotBillable,
      );
      expect(repository.issueCalls, 0);
    });
  });
}

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company'),
    role: role,
  );
}

Invoice _invoice({InvoiceStatus status = InvoiceStatus.draft}) {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  final hundred = Money(minorUnits: 10000, currency: currency);
  final taxRate = TaxRate.tryCreate(0)!;

  return Invoice(
    id: 'invoice-1',
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer',
    ),
    status: status,
    currency: currency,
    lines: [InvoiceTripLine(tripId: 'trip-1', amount: hundred)],
    totals: InvoiceTotals(
      subtotal: hundred,
      discount: zero,
      taxableAmount: hundred,
      taxRate: taxRate,
      taxAmount: zero,
      grandTotal: hundred,
    ),
    createdAt: DateTime.utc(2026, 8, 5),
    updatedAt: DateTime.utc(2026, 8, 5),
  );
}

final class _FixedBusinessDateProvider implements CompanyBusinessDateProvider {
  final Result<DateTime> _result;
  String? lastCompanyId;

  _FixedBusinessDateProvider(DateTime date) : _result = Success(date);

  _FixedBusinessDateProvider.withResult(this._result);

  @override
  Future<Result<DateTime>> getBusinessDate({required String companyId}) async {
    lastCompanyId = companyId;
    return _result;
  }
}

final class _FakeInvoicesRepository implements InvoicesRepository {
  final CurrencyCode _currency = CurrencyCode.tryParse('AED')!;

  int getInvoicesCalls = 0;
  int creationContextCalls = 0;
  int updateDraftCalls = 0;
  int issueCalls = 0;
  int cancelCalls = 0;
  String? lastCompanyId;
  String? lastActorRole;
  List<String>? lastTripIds;
  InvoiceDraftData? lastDraftData;
  Invoice invoiceForDetails = _invoice();
  TripStatus currentTripStatus = TripStatus.documentsReceived;

  @override
  Future<Result<Invoice>> cancelInvoice({
    required String companyId,
    required String invoiceId,
    required String reason,
    required String actorRole,
  }) async {
    cancelCalls++;
    lastCompanyId = companyId;
    lastActorRole = actorRole;
    return Success<Invoice>(_invoice(status: InvoiceStatus.cancelled));
  }

  @override
  Future<Result<Invoice>> createInvoiceDraft({
    required InvoiceDraftData data,
    required String actorRole,
  }) async {
    lastDraftData = data;
    lastActorRole = actorRole;
    return Success<Invoice>(_invoice());
  }

  @override
  Future<Result<List<BillableTrip>>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) async {
    lastCompanyId = companyId;
    return Success<List<BillableTrip>>(_trips());
  }

  @override
  Future<Result<InvoiceCreationContext>> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) async {
    creationContextCalls++;
    lastCompanyId = companyId;
    lastTripIds = List.of(tripIds);
    return Success<InvoiceCreationContext>(
      InvoiceCreationContext(
        customer: const InvoiceCustomerSnapshot(
          companyId: 'company-1',
          customerId: 'customer-1',
          name: 'Customer',
        ),
        isCustomerActive: true,
        trips: _trips(),
      ),
    );
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    lastCompanyId = companyId;
    return Success<Invoice>(invoiceForDetails);
  }

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) async {
    getInvoicesCalls++;
    lastCompanyId = companyId;
    return Success<List<Invoice>>([invoiceForDetails]);
  }

  @override
  Future<Result<Invoice>> issueInvoice({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
    required String actorRole,
  }) async {
    issueCalls++;
    lastCompanyId = companyId;
    lastActorRole = actorRole;
    return Success<Invoice>(_invoice(status: InvoiceStatus.issued));
  }

  @override
  Future<Result<Invoice>> updateInvoiceDraft({
    required String invoiceId,
    required InvoiceDraftData data,
    required String actorRole,
  }) async {
    updateDraftCalls++;
    lastDraftData = data;
    lastActorRole = actorRole;
    return Success<Invoice>(_invoice());
  }

  List<BillableTrip> _trips() {
    return [
      BillableTrip(
        id: 'trip-1',
        companyId: 'company-1',
        customerId: 'customer-1',
        status: currentTripStatus,
        freightAmount: Money(minorUnits: 10000, currency: _currency),
        isAlreadyInvoiced: false,
      ),
      BillableTrip(
        id: 'trip-2',
        companyId: 'company-1',
        customerId: 'customer-1',
        status: currentTripStatus,
        freightAmount: Money(minorUnits: 5000, currency: _currency),
        isAlreadyInvoiced: false,
      ),
    ];
  }
}
