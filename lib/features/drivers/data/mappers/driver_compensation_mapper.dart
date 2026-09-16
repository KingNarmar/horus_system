import '../../../../core/data/utils/db_date.dart';
import '../../../../core/documents/domain/entities/business_document_reference.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/driver_compensation_revision.dart';
import '../../domain/entities/driver_compensation_write_data.dart';
import '../constants/driver_compensation_db_fields.dart';
import '../models/driver_compensation_model.dart';

extension DriverCompensationModelMapper on DriverCompensationModel {
  DriverCompensationRevision toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null) {
      throw const FormatException('Invalid Driver compensation currency.');
    }

    return DriverCompensationRevision(
      id: id,
      companyId: companyId,
      driverId: driverId,
      amount: Money(minorUnits: amountMinorUnits, currency: currency),
      currencyFractionDigits: currencyFractionDigits,
      effectiveFrom: DbDate.decode(
        effectiveFrom,
        field: DriverCompensationDbFields.effectiveFrom,
      ),
      effectiveTo: DbDate.decodeNullable(
        effectiveTo,
        field: DriverCompensationDbFields.effectiveTo,
      ),
      contractReference: contractReference,
      contractDocumentReference: contractDocumentReference == null
          ? null
          : BusinessDocumentReference(contractDocumentReference!),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toAuditValues() {
    return {
      DriverCompensationDbFields.amountMinorUnits: amountMinorUnits,
      DriverCompensationDbFields.currencyCode: currencyCode,
      DriverCompensationDbFields.currencyFractionDigits:
          currencyFractionDigits,
      DriverCompensationDbFields.effectiveFrom: effectiveFrom,
      DriverCompensationDbFields.effectiveTo: effectiveTo,
      DriverCompensationDbFields.contractReference: contractReference,
      'contract_document_attached': contractDocumentReference != null,
    };
  }
}

extension DriverCompensationWriteDataMapper on DriverCompensationWriteData {
  Map<String, dynamic> toInsertMap({
    required String revisionId,
    BusinessDocumentReference? contractDocumentReference,
  }) {
    return {
      DriverCompensationDbFields.id: revisionId,
      DriverCompensationDbFields.companyId: companyId,
      DriverCompensationDbFields.driverId: driverId,
      DriverCompensationDbFields.amountMinorUnits: amount.minorUnits,
      DriverCompensationDbFields.currencyCode: amount.currency.value,
      DriverCompensationDbFields.currencyFractionDigits: currencyFractionDigits,
      DriverCompensationDbFields.effectiveFrom: DbDate.encode(effectiveFrom),
      DriverCompensationDbFields.effectiveTo: DbDate.encodeNullable(effectiveTo),
      DriverCompensationDbFields.contractReference: contractReference,
      DriverCompensationDbFields.contractDocumentReference:
          contractDocumentReference?.value,
    };
  }
}
