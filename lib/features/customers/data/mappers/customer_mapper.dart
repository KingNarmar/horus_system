import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_write_data.dart';
import '../models/customer_model.dart';

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

extension CustomerWriteDataMapper on CustomerWriteData {
  Map<String, dynamic> toInsertMap() {
    return {
      'company_id': companyId,
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'tax_registration_number': taxRegistrationNumber,
      'address': address,
      'city': city,
      'country': country,
      'credit_limit': creditLimit,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'tax_registration_number': taxRegistrationNumber,
      'address': address,
      'city': city,
      'country': country,
      'credit_limit': creditLimit,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
