// Issue #327: pure checks for isolated Development mutation test fixtures.
// This library never performs I/O or writes to Supabase.

abstract final class MutationFixtureContract {
  static const markerPrefix = 'HORUS327-ISOLATED-';
  static const tripMoneyFields = [
    'freight_price',
    'agreed_freight_rate_per_ton',
    'total_expenses',
  ];

  static bool validUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

  static bool validMarker(String value) =>
      value.startsWith(markerPrefix) &&
      value.length >= markerPrefix.length + 8 &&
      value.length <= 120;
}

final class MutationFixtureIds {
  final String companyId;
  final String foreignCompanyId;
  final String tripId;
  final String routeId;
  final String invoicedTripId;
  final String marker;

  const MutationFixtureIds({
    required this.companyId,
    required this.foreignCompanyId,
    required this.tripId,
    required this.routeId,
    required this.invoicedTripId,
    required this.marker,
  });

  bool get valid =>
      [
        companyId,
        foreignCompanyId,
        tripId,
        routeId,
        invoicedTripId,
      ].every(MutationFixtureContract.validUuid) &&
      companyId != foreignCompanyId &&
      tripId != invoicedTripId &&
      MutationFixtureContract.validMarker(marker);
}

abstract final class MutationPreflightChecks {
  static bool activeAuthorizedMember(
    Object? response,
    String userId,
    String companyId,
    String foreignCompanyId,
  ) {
    if (response is! List) return false;
    final rows = response.whereType<Map>().where(
      (row) => row['is_active'] == true && row['user_id'] == userId,
    );
    final authorized = rows.any(
      (row) =>
          row['company_id'] == companyId &&
          (row['role'] == 'owner' || row['role'] == 'admin'),
    );
    return authorized &&
        !rows.any((row) => row['company_id'] == foreignCompanyId);
  }

  static bool isolatedRoute(
    Object? rows,
    MutationFixtureIds ids,
    String expectedCreator,
  ) {
    if (rows is! List || rows.length != 1 || rows.single is! Map) {
      return false;
    }
    final row = rows.single as Map;
    return row['id'] == ids.routeId &&
        row['company_id'] == ids.companyId &&
        row['notes'] == ids.marker &&
        row['created_by'] == expectedCreator &&
        row['is_active'] == true &&
        _timestamp(row['updated_at']);
  }

  static bool isolatedTrip(
    Object? rows,
    MutationFixtureIds ids,
    String expectedCreator,
  ) {
    if (rows is! List || rows.length != 1 || rows.single is! Map) {
      return false;
    }
    final row = rows.single as Map;
    final quantity = row['quantity_tons'];
    return row['id'] == ids.tripId &&
        row['company_id'] == ids.companyId &&
        row['route_id'] == ids.routeId &&
        row['notes'] == ids.marker &&
        row['created_by'] == expectedCreator &&
        row['invoice_id'] == null &&
        quantity is num &&
        quantity > 0 &&
        _timestamp(row['updated_at']);
  }

  static bool isolatedInvoicedTrip(
    Object? rows,
    MutationFixtureIds ids,
    String expectedCreator,
  ) {
    if (rows is! List || rows.length != 1 || rows.single is! Map) {
      return false;
    }
    final row = rows.single as Map;
    final invoiceId = row['invoice_id'];
    return row['id'] == ids.invoicedTripId &&
        row['company_id'] == ids.companyId &&
        row['notes'] == ids.marker &&
        row['created_by'] == expectedCreator &&
        invoiceId is String &&
        MutationFixtureContract.validUuid(invoiceId) &&
        _timestamp(row['updated_at']);
  }

  static bool _timestamp(Object? value) =>
      value is String && DateTime.tryParse(value) != null;
}

final class MutationRpcReply {
  final int status;
  final Object? body;

  const MutationRpcReply(this.status, this.body);

  bool get ok => status >= 200 && status < 300;
}

abstract final class MutationRpcChecks {
  static bool denied(MutationRpcReply reply, String code) =>
      reply.status >= 400 &&
      reply.status < 500 &&
      reply.body is Map &&
      (reply.body as Map)['code'] == code;

  static bool operationalSnapshot(
    MutationRpcReply reply,
    String companyId,
    String tripId,
  ) {
    if (!reply.ok || reply.body is! Map) return false;
    final row = reply.body as Map;
    return row['id'] == tripId &&
        row['company_id'] == companyId &&
        MutationFixtureContract.tripMoneyFields.every(
          (key) => row.containsKey(key) && row[key] == null,
        );
  }

  static bool financeSnapshot(
    MutationRpcReply reply,
    String companyId,
    String tripId,
  ) {
    if (!reply.ok || reply.body is! Map) return false;
    final row = reply.body as Map;
    return row['id'] == tripId &&
        row['company_id'] == companyId &&
        MutationFixtureContract.tripMoneyFields.every(row.containsKey) &&
        row['freight_price'] is num &&
        row['agreed_freight_rate_per_ton'] is num;
  }

  static bool unchanged(Object? before, Object? after) =>
      _sameValue(before, after);

  static bool financialAudit(
    Object? rows, {
    required String companyId,
    required String tripId,
    required String actorUserId,
  }) {
    if (rows is! List || rows.length != 1 || rows.single is! Map) {
      return false;
    }
    final audit = rows.single as Map;
    final meta = audit['metadata'];
    return audit['company_id'] == companyId &&
        audit['entity_id'] == tripId &&
        audit['module'] == 'trips' &&
        audit['entity_type'] == 'trip' &&
        audit['action'] == 'updated' &&
        audit['actor_user_id'] == actorUserId &&
        audit['old_values'] is Map &&
        audit['new_values'] is Map &&
        meta is Map &&
        meta['financial_terms_changed'] == true &&
        !_sameValue(audit['old_values'], audit['new_values']);
  }

  static bool _sameValue(Object? left, Object? right) {
    if (identical(left, right)) return true;
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      return left.keys.every(
        (key) =>
            right.containsKey(key) && _sameValue(left[key], right[key]),
      );
    }
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var i = 0; i < left.length; i++) {
        if (!_sameValue(left[i], right[i])) return false;
      }
      return true;
    }
    return left == right;
  }
}
