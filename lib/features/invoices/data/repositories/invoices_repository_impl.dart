import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_creation_context.dart';
import '../../domain/entities/invoice_draft_data.dart';
import '../../domain/repositories/invoices_repository.dart';
import '../../domain/value_objects/invoice_date.dart';
import '../datasources/invoices_remote_data_source.dart';
import '../mappers/billable_trip_mapper.dart';
import '../mappers/invoice_creation_context_mapper.dart';
import '../mappers/invoice_draft_write_mapper.dart';
import '../mappers/invoice_mapper.dart';
import 'invoices_repository_failure_mapper.dart';

final class InvoicesRepositoryImpl implements InvoicesRepository {
  final InvoicesRemoteDataSource _remoteDataSource;

  const InvoicesRepositoryImpl(this._remoteDataSource);

  static const _failureMapper = InvoicesRepositoryFailureMapper();

  @override
  Future<Result<List<Invoice>>> getInvoices({required String companyId}) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesView,
      action: () async {
        final models = await _remoteDataSource.getInvoices(
          companyId: companyId,
        );
        return models.map((model) => model.toEntity()).toList(growable: false);
      },
    );
  }

  @override
  Future<Result<Invoice>> getInvoiceDetails({
    required String companyId,
    required String invoiceId,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesView,
      action: () async {
        final model = await _remoteDataSource.getInvoiceDetails(
          companyId: companyId,
          invoiceId: invoiceId,
        );
        return model.toEntity();
      },
    );
  }

  @override
  Future<Result<List<BillableTrip>>> getBillableTrips({
    required String companyId,
    String? customerId,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesManagement,
      action: () async {
        final models = await _remoteDataSource.getBillableTrips(
          companyId: companyId,
          customerId: customerId,
        );
        return models.map((model) => model.toEntity()).toList(growable: false);
      },
    );
  }

  @override
  Future<Result<InvoiceCreationContext>> getCreationContext({
    required String companyId,
    required List<String> tripIds,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesManagement,
      action: () async {
        final model = await _remoteDataSource.getCreationContext(
          companyId: companyId,
          tripIds: tripIds,
        );
        return model.toEntity();
      },
    );
  }

  @override
  Future<Result<Invoice>> createInvoiceDraft({
    required InvoiceDraftData data,
    required String actorRole,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesManagement,
      action: () async {
        final model = await _remoteDataSource.createDraft(
          data: data.toWriteModel(),
        );
        return model.toEntity();
      },
    );
  }

  @override
  Future<Result<Invoice>> updateInvoiceDraft({
    required String invoiceId,
    required InvoiceDraftData data,
    required String actorRole,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesManagement,
      action: () async {
        final model = await _remoteDataSource.updateDraft(
          invoiceId: invoiceId,
          data: data.toWriteModel(),
        );
        return model.toEntity();
      },
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
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesIssue,
      action: () async {
        final model = await _remoteDataSource.issue(
          companyId: companyId,
          invoiceId: invoiceId,
          issueDate: issueDate,
          dueDate: dueDate,
        );
        return model.toEntity();
      },
    );
  }

  @override
  Future<Result<Invoice>> cancelInvoice({
    required String companyId,
    required String invoiceId,
    required String reason,
    required String actorRole,
  }) {
    return _execute(
      permissionCode: FailureCodes.permissionInvoicesCancel,
      action: () async {
        final model = await _remoteDataSource.cancel(
          companyId: companyId,
          invoiceId: invoiceId,
          reason: reason,
        );
        return model.toEntity();
      },
    );
  }

  Future<Result<T>> _execute<T>({
    required String permissionCode,
    required Future<T> Function() action,
  }) async {
    try {
      return Success(await action());
    } on AuthException catch (error) {
      return FailureResult(_failureMapper.fromAuthException(error));
    } on PostgrestException catch (error) {
      return FailureResult(
        _failureMapper.fromPostgrest(
          error,
          permissionCode: permissionCode,
        ),
      );
    } on FormatException catch (error) {
      return FailureResult(_failureMapper.fromFormatException(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
