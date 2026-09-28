import '../../domain/entities/account_deletion_request.dart';
import '../models/account_deletion_request_model.dart';

extension AccountDeletionRequestMapper on AccountDeletionRequestModel {
  AccountDeletionRequest toEntity() {
    return AccountDeletionRequest(
      id: id,
      status: AccountDeletionStatus.values.byName(status),
      requestedAt: requestedAt,
      eligibleAfter: eligibleAfter,
    );
  }
}
