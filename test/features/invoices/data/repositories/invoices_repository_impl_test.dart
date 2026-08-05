import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/invoices/data/constants/invoices_rpc_error_codes.dart';
import 'package:horus_system/features/invoices/data/datasources/invoices_remote_data_source.dart';
import 'package:horus_system/features/invoices/data/models/billable_trip_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_creation_context_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_customer_snapshot_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_draft_write_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_totals_model.dart';
import 'package:horus_system/features/invoices/data/models/invoice_trip_line_model.dart';
import 'package:horus_system/features/invoices/data/repositories/invoices_repository_impl.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_customer_snapshot.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_draft_data.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_status.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_totals.dart';
import 'package:horus_system/features/invoices/domain/entities/invoice_trip_line.dart';
import 'package:horus_system/features/invoices/domain/value_objects/invoice_date.dart';
import 'package:horus_system/features/invoices/domain/value_objects/tax_rate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  group('InvoicesRepositoryImpl', () {
    test('maps company-scoped invoice reads to domain entities', () async {
      final dataSource = _FakeInvoicesRemoteDataSource();
      final result = await InvoicesRepositoryImpl(
        dataSource,
      ).getInvoices(companyId: 'company-1');

      expect(result, isA<Success<List<dynamic>>>());
      expect(dataSource.companyId, 'company-1');
      expect(result.dataOrNull?.single.status, InvoiceStatus.draft);
      expect(result.dataOrNull?.single.lines.single.tripId, 'trip-1');
    });

    test('creates a draft from intent and maps the trusted result', () async {
      final dataSource = _FakeInvoicesRemoteDataSource();
      final result = await InvoicesRepositoryImpl(
        dataSource,
      ).createInvoiceDraft(data: _draftData(), actorRole: 'accountant');

      expect(result.dataOrNull?.id, 'invoice-1');
      expect(dataSource.writeModel?.companyId, 'company-1');
      expect(dataSource.writeModel?.customerId, 'customer-1');
      expect(dataSource.writeModel?.tripIds, ['trip-1']);
      expect(dataSource.writeModel?.discountMinorUnits, 500);
    });

    test('maps a double-invoicing SQLSTATE to a typed conflict', () async {
      final dataSource = _FakeInvoicesRemoteDataSource()
        ..issueError = PostgrestException(
          message: 'internal wording',
          code: InvoicesRpcErrorCodes.tripAlreadyInvoiced,
        );
      final result = await InvoicesRepositoryImpl(dataSource).issueInvoice(
        companyId: 'company-1',
        invoiceId: 'invoice-1',
        issueDate: InvoiceDate.fromDateTime(DateTime.utc(2026, 8, 5)),
        dueDate: InvoiceDate.fromDateTime(DateTime.utc(2026, 9, 4)),
        actorRole: 'admin',
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.conflictInvoiceTripAlreadyInvoiced,
      );
      expect(result.failureOrNull?.message, isNull);
    });

    test('maps corrupt persistence data to a server failure', () async {
      final dataSource = _FakeInvoicesRemoteDataSource()
        ..invoiceModel = _invoiceModel(currencyCode: 'INVALID');
      final result = await InvoicesRepositoryImpl(
        dataSource,
      ).getInvoiceDetails(companyId: 'company-1', invoiceId: 'invoice-1');

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.code, FailureCodes.serverError);
    });
  });
}

InvoiceDraftData _draftData() {
  final currency = CurrencyCode.tryParse('AED')!;
  return InvoiceDraftData(
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshot(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer One',
    ),
    currency: currency,
    lines: [
      InvoiceTripLine(
        tripId: 'trip-1',
        amount: Money(minorUnits: 10000, currency: currency),
      ),
    ],
    totals: InvoiceTotals(
      subtotal: Money(minorUnits: 10000, currency: currency),
      discount: Money(minorUnits: 500, currency: currency),
      taxableAmount: Money(minorUnits: 9500, currency: currency),
      taxRate: TaxRate.tryCreate(500)!,
      taxAmount: Money(minorUnits: 475, currency: currency),
      grandTotal: Money(minorUnits: 9975, currency: currency),
    ),
  );
}

InvoiceModel _invoiceModel({String currencyCode = 'AED'}) {
  return InvoiceModel(
    id: 'invoice-1',
    companyId: 'company-1',
    customer: const InvoiceCustomerSnapshotModel(
      companyId: 'company-1',
      customerId: 'customer-1',
      name: 'Customer One',
    ),
    status: 'draft',
    currencyCode: currencyCode,
    lines: [
      InvoiceTripLineModel(
        linePosition: 1,
        tripId: 'trip-1',
        amountMinorUnits: 10000,
        currencyCode: currencyCode,
      ),
    ],
    totals: InvoiceTotalsModel(
      subtotalMinorUnits: 10000,
      discountMinorUnits: 500,
      taxableMinorUnits: 9500,
      taxRateBasisPoints: 500,
      taxMinorUnits: 475,
      totalMinorUnits: 9975,
      currencyCode: currencyCode,
    ),
    createdAt: DateTime.utc(2026, 8, 5),
    updatedAt: DateTime.utc(2026, 8, 5),
  );
}

final class _FakeInvoicesRemoteDataSource implements InvoicesRemoteDataSource {
  String? companyId;
  InvoiceDraftWriteModel? writeModel;
  PostgrestException? issueError;
  InvoiceModel invoiceModel = _invoiceModel();

  @override
  Future<InvoiceModel> cancel({
    required String companyId,
    required String invoiceId,
    required String reason,
  }) async {
    this.companyId = companyId;
    return invoiceModel;
  }

  @override
  Future<InvoiceModel> createDraft({
    required InvoiceDraftWriteModel data,
  }) async {
    companyId = data.companyId;
    writeModel = data;
    return invoiceModel;
  }

  @override
  Future<List<BillableTripModel>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) async {
    this.companyId = companyId;
    return const [];
  }

  @override
  Future<InvoiceCreationContextModel> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<InvoiceModel> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) async {
    this.companyId = companyId;
    return invoiceModel;
  }

  @override
  Future<List<InvoiceModel>> getInvoices({required String companyId}) async {
    this.companyId = companyId;
    return [invoiceModel];
  }

  @override
  Future<InvoiceModel> issue({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
  }) async {
    this.companyId = companyId;
    if (issueError case final error?) throw error;
    return invoiceModel;
  }

  @override
  Future<InvoiceModel> updateDraft({
    required String invoiceId,
    required InvoiceDraftWriteModel data,
  }) async {
    companyId = data.companyId;
    writeModel = data;
    return invoiceModel;
  }
}
