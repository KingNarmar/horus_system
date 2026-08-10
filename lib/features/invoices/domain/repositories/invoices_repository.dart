import '../../../../core/utils/result.dart';
import '../entities/billable_trip.dart';
import '../entities/invoice.dart';
import '../entities/invoice_creation_context.dart';
import '../entities/invoice_draft_data.dart';
import '../value_objects/invoice_date.dart';

abstract class InvoicesRepository {
  Future<Result<List<Invoice>>> getInvoices({required String companyId});

  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  });

  Future<Result<List<BillableTrip>>> getBillableTrips({
    required String companyId,
    String? customerId,
  });

  Future<Result<InvoiceCreationContext>> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  });

  Future<Result<Invoice>> createInvoiceDraft({
    required InvoiceDraftData data,
    required String actorRole,
  });

  Future<Result<Invoice>> updateInvoiceDraft({
    required String invoiceId,
    required InvoiceDraftData data,
    required String actorRole,
  });

  /// Must allocate the number, revalidate the persisted draft and trips,
  /// freeze invoice snapshots, and move trips to invoiced atomically inside
  /// one company-scoped transaction.
  Future<Result<Invoice>> issueInvoice({
    required String companyId,
    required String invoiceId,
    required InvoiceDate issueDate,
    required InvoiceDate dueDate,
    required String actorRole,
  });

  /// Must reject invoices with registered payments and otherwise cancel the
  /// invoice and restore its trips atomically inside one company-scoped
  /// transaction.
  Future<Result<Invoice>> cancelInvoice({
    required String companyId,
    required String invoiceId,
    required String reason,
    required String actorRole,
  });
}
