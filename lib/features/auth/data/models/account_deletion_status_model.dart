import '../../domain/entities/account_deletion_status.dart';
import '../constants/account_deletion_db_fields.dart';

final class AccountDeletionStatusModel {
  final String status;
  final DateTime? requestedAt;
  final DateTime? scheduledFor;

  const AccountDeletionStatusModel({
    required this.status,
    this.requestedAt,
    this.scheduledFor,
  });

  factory AccountDeletionStatusModel.fromJson(Map<String, dynamic> json) {
    return AccountDeletionStatusModel(
      status: json[AccountDeletionDbFields.status] as String,
      requestedAt: _date(json[AccountDeletionDbFields.requestedAt]),
      scheduledFor: _date(json[AccountDeletionDbFields.scheduledFor]),
    );
  }

  AccountDeletionStatus toEntity() {
    return AccountDeletionStatus(
      state: status == 'pending'
          ? AccountDeletionRequestState.pending
          : AccountDeletionRequestState.none,
      requestedAt: requestedAt,
      scheduledFor: scheduledFor,
    );
  }

  static DateTime? _date(Object? value) {
    return value is String ? DateTime.tryParse(value) : null;
  }
}
