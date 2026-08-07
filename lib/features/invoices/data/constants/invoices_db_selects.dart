import '../../../../core/data/constants/db_common_fields.dart';
import 'invoices_db_fields.dart';

abstract final class InvoicesDbSelects {
  static final aggregate = <String>[
    DbCommonFields.id,
    DbCommonFields.companyId,
    InvoicesDbFields.customerId,
    InvoicesDbFields.status,
    InvoicesDbFields.invoiceNumber,
    InvoicesDbFields.currencyCode,
    InvoicesDbFields.customerName,
    InvoicesDbFields.customerTaxRegistrationNumber,
    InvoicesDbFields.customerAddress,
    InvoicesDbFields.customerCity,
    InvoicesDbFields.customerCountry,
    InvoicesDbFields.subtotalMinorUnits,
    InvoicesDbFields.discountMinorUnits,
    InvoicesDbFields.taxableMinorUnits,
    InvoicesDbFields.taxRateBasisPoints,
    InvoicesDbFields.taxMinorUnits,
    InvoicesDbFields.totalMinorUnits,
    InvoicesDbFields.issueDate,
    InvoicesDbFields.dueDate,
    InvoicesDbFields.notes,
    InvoicesDbFields.cancellationReason,
    DbCommonFields.createdAt,
    DbCommonFields.updatedAt,
    '${InvoicesDbFields.linesRelation}(${_lineColumns.join(',')})',
  ].join(',');

  static const _lineColumns = <String>[
    InvoicesDbFields.linePosition,
    InvoicesDbFields.tripId,
    InvoicesDbFields.tripNumber,
    InvoicesDbFields.loadingLocation,
    InvoicesDbFields.unloadingLocation,
    InvoicesDbFields.loadingOrderNumber,
    InvoicesDbFields.waybillNumber,
    InvoicesDbFields.serviceDate,
    InvoicesDbFields.quantityTons,
    InvoicesDbFields.amountMinorUnits,
    InvoicesDbFields.currencyCode,
  ];
}
