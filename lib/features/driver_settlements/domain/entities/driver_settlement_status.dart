enum DriverSettlementStatus {
  draft,
  finalized,
  voided;

  String get value {
    return switch (this) {
      DriverSettlementStatus.draft => 'draft',
      DriverSettlementStatus.finalized => 'finalized',
      DriverSettlementStatus.voided => 'voided',
    };
  }

  static DriverSettlementStatus fromValue(String value) {
    return DriverSettlementStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DriverSettlementStatus.draft,
    );
  }
}
