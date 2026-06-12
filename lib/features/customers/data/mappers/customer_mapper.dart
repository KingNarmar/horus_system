import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_write_data.dart';
import '../models/customer_model.dart';
import '../../../../core/data/constants/db_common_fields.dart';
import '../../../../core/data/utils/db_timestamp.dart';
import '../constants/customer_db_fields.dart';

extension CustomerModelMapper on CustomerModel {
  Customer toEntity() {
    return Customer(
      id: id,
      companyId: companyId,
      name: name,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      taxRegistrationNumber: taxRegistrationNumber,
      address: address,
      city: city,
      country: country,
      creditLimit: creditLimit,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension CustomerAuditMapper on CustomerModel {
  Map<String, Object?> toAuditValues() {
    return {
      DbCommonFields.id: id,
      DbCommonFields.companyId: companyId,
      CustomerDbFields.name: name,
      CustomerDbFields.contactPerson: contactPerson,
      CustomerDbFields.phone: phone,
      CustomerDbFields.email: email,
      CustomerDbFields.taxRegistrationNumber: taxRegistrationNumber,
      CustomerDbFields.address: address,
      CustomerDbFields.city: city,
      CustomerDbFields.country: country,
      CustomerDbFields.creditLimit: creditLimit,
      DbCommonFields.isActive: isActive,
      DbCommonFields.createdAt: createdAt?.toUtc().toIso8601String(),
      DbCommonFields.updatedAt: updatedAt?.toUtc().toIso8601String(),
    };
  }
}

extension CustomerWriteDataMapper on CustomerWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      DbCommonFields.companyId: companyId,
      CustomerDbFields.name: name,
      CustomerDbFields.contactPerson: contactPerson,
      CustomerDbFields.phone: phone,
      CustomerDbFields.email: email,
      CustomerDbFields.taxRegistrationNumber: taxRegistrationNumber,
      CustomerDbFields.address: address,
      CustomerDbFields.city: city,
      CustomerDbFields.country: country,
      CustomerDbFields.creditLimit: creditLimit,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      CustomerDbFields.name: name,
      CustomerDbFields.contactPerson: contactPerson,
      CustomerDbFields.phone: phone,
      CustomerDbFields.email: email,
      CustomerDbFields.taxRegistrationNumber: taxRegistrationNumber,
      CustomerDbFields.address: address,
      CustomerDbFields.city: city,
      CustomerDbFields.country: country,
      CustomerDbFields.creditLimit: creditLimit,
      DbCommonFields.updatedAt: DbTimestamp.nowUtcIsoString(),
    };
  }
}
