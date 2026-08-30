import '../models/company_invitation_delivery_preparation_model.dart';

abstract class CompanyInvitationDeliveryRemoteDataSource {
  Future<void> send({
    required CompanyInvitationDeliveryPreparationModel preparation,
    required String rawToken,
  });
}

class CompanyInvitationDeliveryException implements Exception {
  final String code;

  const CompanyInvitationDeliveryException(this.code);
}
