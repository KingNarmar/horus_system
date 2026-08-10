import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
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
import 'package:horus_system/features/invoices/domain/usecases/invoice_query_usecases.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_draft_form_input.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoices_cubit.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoices_state.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  late _FakeInvoicesRepository repository;
  late InvoicesCubit cubit;

  setUp(() {
    repository = _FakeInvoicesRepository();
    cubit = InvoicesCubit(
      getInvoicesUseCase: GetInvoicesUseCase(repository),
      getBillableTripsUseCase: GetBillableTripsUseCase(repository),
      createInvoiceFromTripUseCase: CreateInvoiceFromTripUseCase(repository),
      updateInvoiceDraftUseCase: UpdateInvoiceDraftUseCase(repository),
    );
  });

  tearDown(() => cubit.close());

  test('loads company invoices and billable trips for accountant', () async {
    repository.invoices = [_invoice(id: 'invoice-1')];
    repository.billableTrips = [_billableTrip(id: 'trip-1')];

    await cubit.loadInvoices(_context());

    final state = cubit.state as InvoicesLoaded;
    expect(state.allInvoices, hasLength(1));
    expect(state.billableTrips, hasLength(1));
    expect(state.canManageInvoiceDrafts, isTrue);
    expect(repository.billableTripsCalls, 1);
  });

  test('viewer loads invoices without requesting draft-only data', () async {
    repository.invoices = [_invoice(id: 'invoice-1')];

    await cubit.loadInvoices(_context(role: CompanyRole.viewer));

    final state = cubit.state as InvoicesLoaded;
    expect(state.allInvoices, hasLength(1));
    expect(state.billableTrips, isEmpty);
    expect(state.canManageInvoiceDrafts, isFalse);
    expect(repository.billableTripsCalls, 0);
  });

  test('a stale company response cannot replace the active tenant', () async {
    final companyAResult = Completer<List<Invoice>>();
    final companyBResult = Completer<List<Invoice>>();
    repository.invoiceCompleters = {
      'company-a': companyAResult,
      'company-b': companyBResult,
    };

    final firstLoad = cubit.loadInvoices(_context(companyId: 'company-a'));
    final secondLoad = cubit.loadInvoices(_context(companyId: 'company-b'));

    companyBResult.complete([
      _invoice(id: 'invoice-b', companyId: 'company-b'),
    ]);
    await secondLoad;

    companyAResult.complete([
      _invoice(id: 'invoice-a', companyId: 'company-a'),
    ]);
    await firstLoad;

    final state = cubit.state as InvoicesLoaded;
    expect(state.currentCompanyContext.companyId, 'company-b');
    expect(state.allInvoices.single.id, 'invoice-b');
  });

  test(
    'creating a draft upserts the list and exposes scoped feedback',
    () async {
      final trip = _billableTrip(id: 'trip-1');
      repository.billableTrips = [trip];
      await cubit.loadInvoices(_context());

      final created = await cubit.createDraftFromTrip(
        InvoiceDraftFormInput.fromBillableTrip(trip),
      );

      final state = cubit.state as InvoicesLoaded;
      expect(created, isTrue);
      expect(state.allInvoices.single.id, 'created-draft');
      expect(state.feedback, InvoiceListFeedback.draftCreated);
      expect(state.isCreatingDraft, isFalse);
    },
  );
}

CurrentCompanyContext _context({
  String companyId = 'company-1',
  CompanyRole role = CompanyRole.accountant,
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Test Company'),
    role: role,
  );
}

final CurrencyCode _currency = CurrencyCode.tryParse('AED')!;
final TaxRate _zeroTax = TaxRate.tryCreate(0)!;

BillableTrip _billableTrip({
  required String id,
  String companyId = 'company-1',
  String customerId = 'customer-1',
}) {
  return BillableTrip(
    id: id,
    companyId: companyId,
    customerId: customerId,
    status: TripStatus.documentsReceived,
    freightAmount: Money(minorUnits: 10000, currency: _currency),
    isAlreadyInvoiced: false,
    loadingOrderNumber: 'LO-$id',
  );
}

Invoice _invoice({
  required String id,
  String companyId = 'company-1',
  String customerId = 'customer-1',
}) {
  final line = InvoiceTripLine.fromBillableTrip(
    _billableTrip(id: 'trip-$id', companyId: companyId, customerId: customerId),
  );
  final subtotal = line.amount;
  final zero = Money(minorUnits: 0, currency: _currency);
  return Invoice(
    id: id,
    companyId: companyId,
    customer: InvoiceCustomerSnapshot(
      companyId: companyId,
      customerId: customerId,
      name: 'Customer $customerId',
    ),
    status: InvoiceStatus.draft,
    currency: _currency,
    lines: [line],
    totals: InvoiceTotals(
      subtotal: subtotal,
      discount: zero,
      taxableAmount: subtotal,
      taxRate: _zeroTax,
      taxAmount: zero,
      grandTotal: subtotal,
    ),
    createdAt: DateTime.utc(2026, 8, 6),
    updatedAt: DateTime.utc(2026, 8, 6),
  );
}

final class _FakeInvoicesRepository implements InvoicesRepository {
  List<Invoice> invoices = [];
  List<BillableTrip> billableTrips = [];
  Map<String, Completer<List<Invoice>>> invoiceCompleters = {};
  int billableTripsCalls = 0;

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) async {
    final completer = invoiceCompleters[companyId];
    if (completer != null) return Success(await completer.future);
    return Success(
      invoices.where((invoice) => invoice.companyId == companyId).toList(),
    );
  }

  @override
  Future<Result<List<BillableTrip>>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) async {
    billableTripsCalls++;
    return Success(
      billableTrips.where((trip) {
        return trip.companyId == companyId &&
            (customerId == null || trip.customerId == customerId);
      }).toList(),
    );
  }

  @override
  Future<Result<InvoiceCreationContext>> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) async {
    final selectedTrips = billableTrips
        .where(
          (trip) => trip.companyId == companyId && tripIds.contains(trip.id),
        )
        .toList(growable: false);
    final customerId = selectedTrips.first.customerId;
    return Success(
      InvoiceCreationContext(
        customer: InvoiceCustomerSnapshot(
          companyId: companyId,
          customerId: customerId,
          name: 'Customer $customerId',
        ),
        isCustomerActive: true,
        trips: selectedTrips,
      ),
    );
  }

  @override
  Future<Result<Invoice>> createInvoiceDraft({
    required InvoiceDraftData data,
    required String actorRole,
  }) async {
    final invoice = _invoiceFromDraft(id: 'created-draft', data: data);
    invoices = [invoice, ...invoices];
    return Success(invoice);
  }

  @override
  Future<Result<Invoice>> updateInvoiceDraft({
    required String invoiceId,
    required InvoiceDraftData data,
    required String actorRole,
  }) async {
    final invoice = _invoiceFromDraft(id: invoiceId, data: data);
    invoices = invoices
        .map((item) => item.id == invoiceId ? invoice : item)
        .toList(growable: false);
    return Success(invoice);
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    return Success(
      invoices.firstWhere(
        (invoice) => invoice.companyId == companyId && invoice.id == invoiceId,
      ),
    );
  }

  @override
  Future<Result<Invoice>> issueInvoice({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Invoice>> cancelInvoice({
    required String companyId,
    required String invoiceId,
    required String reason,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  Invoice _invoiceFromDraft({
    required String id,
    required InvoiceDraftData data,
  }) {
    return Invoice(
      id: id,
      companyId: data.companyId,
      customer: data.customer,
      status: InvoiceStatus.draft,
      currency: data.currency,
      lines: data.lines,
      totals: data.totals,
      issueDate: data.issueDate,
      dueDate: data.dueDate,
      notes: data.notes,
      createdAt: DateTime.utc(2026, 8, 6),
      updatedAt: DateTime.utc(2026, 8, 6),
    );
  }
}
