import '../../../../core/data/constants/db_common_fields.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_method_write_data.dart';
import '../constants/payment_method_db_fields.dart';
import '../models/payment_method_model.dart';

extension PaymentMethodModelMapper on PaymentMethodModel {
  PaymentMethod toEntity() {
    return PaymentMethod(
      id: id,
      companyId: companyId,
      name: name,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension PaymentMethodAuditMapper on PaymentMethodModel {
  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      PaymentMethodDbFields.name: name,
      PaymentMethodDbFields.code: code,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdBy: createdBy,
      DbCommonFields.updatedBy: updatedBy,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension PaymentMethodWriteDataMapper on PaymentMethodWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      PaymentMethodDbFields.name: name,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {PaymentMethodDbFields.name: name};
  }
}
