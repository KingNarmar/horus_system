enum CompanyInvitationStatus {
  pending,
  accepted,
  expired,
  revoked;

  static CompanyInvitationStatus fromDatabase(String value) {
    return switch (value) {
      'pending' => CompanyInvitationStatus.pending,
      'accepted' => CompanyInvitationStatus.accepted,
      'expired' => CompanyInvitationStatus.expired,
      'revoked' => CompanyInvitationStatus.revoked,
      _ => throw ArgumentError.value(value, 'value'),
    };
  }
}
