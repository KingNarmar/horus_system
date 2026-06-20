enum TripStatus {
  created,
  assigned,
  loaded,
  onRoad,
  arrived,
  delivered,
  documentsReceived,
  invoiced,
  paid,
  cancelled,
}

extension TripStatusX on TripStatus {
  String get value {
    return switch (this) {
      TripStatus.created => 'created',
      TripStatus.assigned => 'assigned',
      TripStatus.loaded => 'loaded',
      TripStatus.onRoad => 'on_road',
      TripStatus.arrived => 'arrived',
      TripStatus.delivered => 'delivered',
      TripStatus.documentsReceived => 'documents_received',
      TripStatus.invoiced => 'invoiced',
      TripStatus.paid => 'paid',
      TripStatus.cancelled => 'cancelled',
    };
  }

  bool get isTerminal {
    return switch (this) {
      TripStatus.paid || TripStatus.cancelled => true,
      TripStatus.created ||
      TripStatus.assigned ||
      TripStatus.loaded ||
      TripStatus.onRoad ||
      TripStatus.arrived ||
      TripStatus.delivered ||
      TripStatus.documentsReceived ||
      TripStatus.invoiced => false,
    };
  }

  bool get blocksVehicleAssignment {
    return switch (this) {
      TripStatus.created ||
      TripStatus.assigned ||
      TripStatus.loaded ||
      TripStatus.onRoad ||
      TripStatus.arrived => true,
      TripStatus.delivered ||
      TripStatus.documentsReceived ||
      TripStatus.invoiced ||
      TripStatus.paid ||
      TripStatus.cancelled => false,
    };
  }

  List<TripStatus> get allowedNextStatuses {
    return switch (this) {
      TripStatus.created => const [TripStatus.assigned, TripStatus.cancelled],
      TripStatus.assigned => const [TripStatus.loaded, TripStatus.cancelled],
      TripStatus.loaded => const [TripStatus.onRoad, TripStatus.cancelled],
      TripStatus.onRoad => const [TripStatus.arrived, TripStatus.cancelled],
      TripStatus.arrived => const [TripStatus.delivered, TripStatus.cancelled],
      TripStatus.delivered => const [TripStatus.documentsReceived],
      TripStatus.documentsReceived => const [TripStatus.invoiced],
      TripStatus.invoiced => const [TripStatus.paid],
      TripStatus.paid => const [],
      TripStatus.cancelled => const [],
    };
  }

  bool canMoveTo(TripStatus nextStatus) {
    if (this == nextStatus) return true;
    return allowedNextStatuses.contains(nextStatus);
  }

  static TripStatus fromValue(String? value) {
    return TripStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TripStatus.created,
    );
  }
}
