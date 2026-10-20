// Issue #327 financial read authorization checks using genuine signed JWTs.
// Read-only RPCs only: legacy Trip mutations are deliberately excluded.
// Responses are inspected in memory; no financial amounts or JWTs are logged.

typedef SignedFinancialRpc = Future<FinancialRpcReply> Function(
  String name,
  Map<String, Object?> params,
);

typedef FinancialReadCheck = Future<void> Function(
  String label,
  Future<bool> Function() assertion,
);

typedef FinancialFixtureLookup = Future<String?> Function(String fixture);
typedef FinancialReadSkip = void Function(String label);

final class FinancialRpcReply {
  final int status;
  final Object? body;

  const FinancialRpcReply(this.status, this.body);

  bool get ok => status >= 200 && status < 300;
}

abstract final class FinancialReadFixtures {
  static const customer = 'customer';
  static const finalizedDriver = 'finalized_driver';
}

abstract final class _RpcNames {
  static const operational = 'get_operational_trip_reports_source';
  static const expenses = 'get_trip_expenses_report_source';
  static const netProfit = 'get_trip_net_profit_report_source';
  static const openInvoices = 'get_open_invoices_report_source';
  static const dashboard = 'get_dashboard_source';
  static const statement = 'get_customer_statement_source';
  static const checkpoint = 'get_driver_balance_checkpoint';
  static const checkpointV2 = 'get_driver_balance_checkpoint_v2';
}

const _reportRpcs = [
  _RpcNames.operational,
  _RpcNames.expenses,
  _RpcNames.netProfit,
  _RpcNames.openInvoices,
];

const _financialKeys = {
  'freight_price',
  'agreed_freight_rate_per_ton',
  'total_expenses',
  'amount_minor_units',
  'total_minor_units',
  'revenue_minor_units',
  'trip_expenses_minor_units',
  'company_expenses_minor_units',
  'net_profit_minor_units',
};

Map<String, Object?> _reportParams(String companyId) => {
  'p_company_id': companyId,
  'p_from_date': null,
  'p_to_date': null,
};

bool _denied(FinancialRpcReply response, String code) {
  final body = response.body;
  return !response.ok && body is Map && body['code'] == code;
}

bool _companyResponse(FinancialRpcReply response, String companyId) {
  final body = response.body;
  return response.ok &&
      body is Map &&
      body['company'] is Map &&
      (body['company'] as Map)['company_id'] == companyId;
}

bool _containsFinancialKey(Object? value) {
  if (value is Map) {
    if (value.keys.any((key) => _financialKeys.contains(key))) {
      return true;
    }
    return value.values.any(_containsFinancialKey);
  }
  if (value is List) return value.any(_containsFinancialKey);
  return false;
}

bool _masked(Object? value) {
  if (value == null) return true;
  if (value is num) return value == 0;
  if (value is Map) return value.values.every(_masked);
  return false;
}

bool _dashboardRead(
  FinancialRpcReply response,
  String companyId,
  bool finance,
) {
  if (!_companyResponse(response, companyId)) return false;
  final body = response.body as Map;
  final metrics = body['metrics'];
  if (metrics is! Map) return false;

  final financial = body['financial'];
  if (finance) {
    return financial is Map &&
        financial['revenue_minor_units'] is num &&
        financial['trip_expenses_minor_units'] is num &&
        financial['company_expenses_minor_units'] is num;
  }

  // INVOKER + finance-only RLS must not expose actual amounts or validation
  // counters through JSON, even though Flutter hides the corresponding cards.
  final validation = body['validation'];
  return _masked(financial) &&
      _masked(validation) &&
      (metrics['unpaid_invoices'] == null || metrics['unpaid_invoices'] == 0);
}

Future<void> verifyFinancialReadAccess({
  required String role,
  required String companyId,
  required String foreignCompanyId,
  required SignedFinancialRpc rpc,
  required FinancialReadCheck check,
  required FinancialReadSkip skip,
  required FinancialFixtureLookup fixtureId,
}) async {
  final finance =
      role == 'owner' || role == 'admin' || role == 'accountant';
  final driver = role == 'driver';

  for (final name in _reportRpcs) {
    final permitted = name == _RpcNames.operational ? !driver : finance;
    await check('$role $name own-tenant authorization', () async {
      final reply = await rpc(name, _reportParams(companyId));
      if (!permitted) return _denied(reply, 'P3010');
      if (!_companyResponse(reply, companyId)) return false;
      // Operational-only reports must not silently expose monetary JSON.
      return name != _RpcNames.operational ||
          !_containsFinancialKey(reply.body);
    });
    await check('$role $name foreign-tenant denial', () async {
      final reply = await rpc(name, _reportParams(foreignCompanyId));
      return _denied(reply, 'P3010');
    });
  }

  await check('$role dashboard own-tenant financial boundary', () async {
    final reply = await rpc(_RpcNames.dashboard, {
      'p_company_id': companyId,
    });
    return driver
        ? _denied(reply, 'P2910')
        : _dashboardRead(reply, companyId, finance);
  });
  await check('$role dashboard foreign-tenant denial', () async {
    final reply = await rpc(_RpcNames.dashboard, {
      'p_company_id': foreignCompanyId,
    });
    return _denied(reply, 'P2910');
  });

  final customerId = finance
      ? await fixtureId(FinancialReadFixtures.customer)
      : '00000000-0000-0000-0000-000000000000';
  if (customerId == null) {
    skip('$role customer statement positive fixture unavailable');
  } else {
    await check('$role customer statement own-tenant authorization', () async {
      final reply = await rpc(_RpcNames.statement, {
        'p_company_id': companyId,
        'p_customer_id': customerId,
        'p_from_date': null,
        'p_to_date': null,
      });
      if (!finance) return _denied(reply, 'P2810');
      final body = reply.body;
      return _companyResponse(reply, companyId) &&
          body is Map &&
          body['customer'] is Map &&
          (body['customer'] as Map)['customer_id'] == customerId;
    });
  }
  await check('$role customer statement foreign-tenant denial', () async {
    final reply = await rpc(_RpcNames.statement, {
      'p_company_id': foreignCompanyId,
      'p_customer_id': customerId ??
          '00000000-0000-0000-0000-000000000000',
      'p_from_date': null,
      'p_to_date': null,
    });
    return _denied(reply, 'P2810');
  });

  final driverId = finance
      ? await fixtureId(FinancialReadFixtures.finalizedDriver)
      : '00000000-0000-0000-0000-000000000000';
  for (final name in [_RpcNames.checkpoint, _RpcNames.checkpointV2]) {
    if (driverId == null) {
      skip('$role $name positive finalized-settlement fixture unavailable');
    } else {
      await check('$role $name own-tenant authorization', () async {
        final reply = await rpc(name, {
          'p_company_id': companyId,
          'p_driver_id': driverId,
          'p_before_exclusive': null,
        });
        if (!finance) return _denied(reply, '42501');
        // A successful empty result does not prove financial visibility.
        return reply.ok && reply.body is List &&
            (reply.body as List).isNotEmpty;
      });
    }
    await check('$role $name foreign-tenant denial', () async {
      final reply = await rpc(name, {
        'p_company_id': foreignCompanyId,
        'p_driver_id': driverId ??
            '00000000-0000-0000-0000-000000000000',
        'p_before_exclusive': null,
      });
      return _denied(reply, '42501');
    });
  }
}
