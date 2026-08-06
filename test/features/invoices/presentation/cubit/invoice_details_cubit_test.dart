import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_action.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
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
import 'package:horus_system/features/invoices/domain/usecases/invoice_lifecycle_usecases.dart';
import 'package:horus_system/features/invoices/domain/usecases/invoice_query_usecases.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_details_cubit.dart';
import 'package:horus_system/features/invoices/presentation/cubit/invoice_details_state.dart';
import 'package:horus_system/features/trips/domain/entities/trip_status.dart';

void main() {
  late _FakeInvoicesRepository repository;
  late _FakeAuditLogRepository auditRepository;
  late InvoiceDetailsCubit cubit;

  setUp(() {
    repository = _FakeInvoicesRepository();
    auditRepository = _FakeAuditLogRepository();
    cubit = InvoiceDetailsCubit(
      getInvoiceDetailsUseCase: GetInvoiceDetailsUseCase(repository),
      issueInvoiceUseCase: IssueInvoiceUseCase(
        repository,
        businessDateProvider: const _FakeBusinessDateProvider(),
      ),
      cancelInvoiceUseCase: CancelInvoiceUseCase(repository),
      getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(auditRepository),
    );
  });

  tearDown(() => cubit.close());

  test('loads invoice details and invoice-scoped audit activity', () async {
    repository.invoice = _invoice();
    auditRepository.logs = [_auditLog()];

    await cubit.loadInvoiceDetails(
      currentCompanyContext: _context(),
      invoiceId: 'invoice-1',
    );

    final state = cubit.state as InvoiceDetailsLoaded;
    expect(state.invoice.id, 'invoice-1');
    expect(state.activity, hasLength(1));
    expect(state.isActivityLoading, isFalse);
    expect(state.canIssue, isTrue);
  });

  test(
    'issuing updates details without returning to full-page loading',
    () async {
      repository.invoice = _invoice();
      await cubit.loadInvoiceDetails(
        currentCompanyContext: _context(),
        invoiceId: 'invoice-1',
      );

      final issued = await cubit.issueInvoice(
        issueDate: DateTime.utc(2026, 8, 6),
        dueDate: DateTime.utc(2026, 8, 31),
      );

      final state = cubit.state as InvoiceDetailsLoaded;
      expect(issued, isTrue);
      expect(state.invoice.status, InvoiceStatus.issued);
      expect(state.feedback, InvoiceDetailsFeedback.issued);
      expect(state.pendingAction, isNull);
    },
  );

  test(
    'cancelling updates the selected invoice and preserves feedback',
    () async {
      repository.invoice = _invoice(status: InvoiceStatus.issued);
      await cubit.loadInvoiceDetails(
        currentCompanyContext: _context(),
        invoiceId: 'invoice-1',
      );

      final cancelled = await cubit.cancelInvoice(reason: 'Customer request');

      final state = cubit.state as InvoiceDetailsLoaded;
      expect(cancelled, isTrue);
      expect(state.invoice.status, InvoiceStatus.cancelled);
      expect(state.invoice.cancellationReason, 'Customer request');
      expect(state.feedback, InvoiceDetailsFeedback.cancelled);
    },
  );

  test('a stale details response cannot replace the active tenant', () async {
    final companyAResult = Completer<Invoice>();
    final companyBResult = Completer<Invoice>();
    repository.detailsCompleters = {
      'company-a': companyAResult,
      'company-b': companyBResult,
    };

    final firstLoad = cubit.loadInvoiceDetails(
      currentCompanyContext: _context(companyId: 'company-a'),
      invoiceId: 'invoice-a',
    );
    final secondLoad = cubit.loadInvoiceDetails(
      currentCompanyContext: _context(companyId: 'company-b'),
      invoiceId: 'invoice-b',
    );

    companyBResult.complete(_invoice(id: 'invoice-b', companyId: 'company-b'));
    await secondLoad;

    companyAResult.complete(_invoice(id: 'invoice-a', companyId: 'company-a'));
    await firstLoad;

    final state = cubit.state as InvoiceDetailsLoaded;
    expect(state.currentCompanyContext.companyId, 'company-b');
    expect(state.invoice.id, 'invoice-b');
  });
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

BillableTrip _trip({
  String id = 'trip-1',
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
  String id = 'invoice-1',
  String companyId = 'company-1',
  String customerId = 'customer-1',
  InvoiceStatus status = InvoiceStatus.draft,
  InvoiceDate? issueDate,
  InvoiceDate? dueDate,
  String? cancellationReason,
}) {
  final line = InvoiceTripLine.fromBillableTrip(
    _trip(companyId: companyId, customerId: customerId),
  );
  final zero = Money(minorUnits: 0, currency: _currency);
  return Invoice(
    id: id,
    companyId: companyId,
    customer: InvoiceCustomerSnapshot(
      companyId: companyId,
      customerId: customerId,
      name: 'Customer $customerId',
    ),
    status: status,
    currency: _currency,
    lines: [line],
    totals: InvoiceTotals(
      subtotal: line.amount,
      discount: zero,
      taxableAmount: line.amount,
      taxRate: _zeroTax,
      taxAmount: zero,
      grandTotal: line.amount,
    ),
    issueDate: issueDate,
    dueDate: dueDate,
    cancellationReason: cancellationReason,
    createdAt: DateTime.utc(2026, 8, 6),
    updatedAt: DateTime.utc(2026, 8, 6),
  );
}

AuditLog _auditLog() {
  return AuditLog(
    id: 'audit-1',
    companyId: 'company-1',
    module: AuditModule.invoices,
    entityType: AuditEntityType.invoice,
    entityId: 'invoice-1',
    action: AuditAction.created,
    description: 'invoice_created',
    createdAt: DateTime.utc(2026, 8, 6),
  );
}

final class _FakeBusinessDateProvider implements CompanyBusinessDateProvider {
  const _FakeBusinessDateProvider();

  @override
  Future<Result<DateTime>> getBusinessDate({required String companyId}) async {
    return Success(DateTime.utc(2026, 8, 6));
  }
}

final class _FakeInvoicesRepository implements InvoicesRepository {
  Invoice? invoice;
  Map<String, Completer<Invoice>> detailsCompleters = {};

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    final completer = detailsCompleters[companyId];
    if (completer != null) return Success(await completer.future);
    return Success(invoice!);
  }

  @override
  Future<Result<InvoiceCreationContext>> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) async {
    final current = invoice!;
    return Success(
      InvoiceCreationContext(
        customer: current.customer,
        isCustomerActive: true,
        trips: [
          _trip(
            id: tripIds.single,
            companyId: companyId,
            customerId: current.customer.customerId,
          ),
        ],
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
  }) async {
    invoice = _copyInvoice(
      invoice!,
      status: InvoiceStatus.issued,
      issueDate: issueDate,
      dueDate: dueDate,
    );
    return Success(invoice!);
  }

  @override
  Future<Result<Invoice>> cancelInvoice({
    required String companyId,
    required String invoiceId,
    required String reason,
    required String actorRole,
  }) async {
    invoice = _copyInvoice(
      invoice!,
      status: InvoiceStatus.cancelled,
      cancellationReason: reason,
    );
    return Success(invoice!);
  }

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<BillableTrip>>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Invoice>> createInvoiceDraft({
    required InvoiceDraftData data,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Invoice>> updateInvoiceDraft({
    required String invoiceId,
    required InvoiceDraftData data,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  Invoice _copyInvoice(
    Invoice source, {
    required InvoiceStatus status,
    InvoiceDate? issueDate,
    InvoiceDate? dueDate,
    String? cancellationReason,
  }) {
    return Invoice(
      id: source.id,
      companyId: source.companyId,
      customer: source.customer,
      status: status,
      number: source.number,
      currency: source.currency,
      lines: source.lines,
      totals: source.totals,
      issueDate: issueDate ?? source.issueDate,
      dueDate: dueDate ?? source.dueDate,
      notes: source.notes,
      cancellationReason: cancellationReason ?? source.cancellationReason,
      createdAt: source.createdAt,
      updatedAt: DateTime.utc(2026, 8, 6, 12),
    );
  }
}

final class _FakeAuditLogRepository implements AuditLogRepository {
  List<AuditLog> logs = [];

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return Success(
      logs
          .where((log) {
            return log.companyId == companyId &&
                log.module == module &&
                log.entityType == entityType &&
                log.entityId == entityId;
          })
          .toList(growable: false),
    );
  }

  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    return const Success<void>(null);
  }
}
