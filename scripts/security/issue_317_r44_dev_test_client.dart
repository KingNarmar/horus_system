// Development-only HTTP/auth fixture shared by Issue #317 R4.4 security tests.
// Not imported by lib/, never accepts a Production endpoint or privileged key.
import 'dart:convert';
import 'dart:io';

const r44DevHost = 'zwnfmszssxtfxkaofnhq.supabase.co';
const r44NetworkTimeout = Duration(seconds: 20);
final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

bool isR44Uuid(String value) => _uuid.hasMatch(value);

final class R44DevConfig {
  final Uri origin;
  final String key;
  final String companyA;
  final String companyB;

  const R44DevConfig(this.origin, this.key, this.companyA, this.companyB);

  factory R44DevConfig.fromEnvironment() {
    String required(String name, [String? fallback]) {
      final first = Platform.environment[name]?.trim();
      final second =
          fallback == null ? null : Platform.environment[fallback]?.trim();
      if (first != null && first.isNotEmpty) return first;
      if (second != null && second.isNotEmpty) return second;
      throw FormatException('Missing Development environment: $name');
    }

    final uri = Uri.tryParse(required('SUPABASE_URL'));
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != r44DevHost ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      throw const FormatException('Development URL is not approved.');
    }
    final key = required('SUPABASE_PUBLISHABLE_KEY');
    if (!key.startsWith('sb_publishable_') ||
        key.length <= 'sb_publishable_'.length) {
      throw const FormatException('A Development publishable key is required.');
    }
    final a = required('HORUS_317_COMPANY_A_ID', 'HORUS_327_COMPANY_A_ID');
    final b = required('HORUS_317_COMPANY_B_ID', 'HORUS_327_COMPANY_B_ID');
    if (!isR44Uuid(a) || !isR44Uuid(b) || a.toLowerCase() == b.toLowerCase()) {
      throw const FormatException('Two distinct Development companies required.');
    }
    return R44DevConfig(uri, key, a, b);
  }

  Uri websocketAddress() => origin.replace(
    scheme: 'wss',
    path: '/realtime/v1/websocket',
    queryParameters: {'apikey': key, 'vsn': '1.0.0'},
  );
}

final class R44Reply {
  final int status;
  final Object? body;

  const R44Reply(this.status, this.body);

  bool get ok => status >= 200 && status < 300;
  String? get sqlState =>
      body is Map ? (body as Map)['code']?.toString() : null;

  List<Map<String, dynamic>> get rows {
    final value = body;
    if (!ok || value is! List) {
      throw const FormatException('Development read response invalid.');
    }
    return value
        .map((row) {
          if (row is! Map) {
            throw const FormatException('Development row invalid.');
          }
          return Map<String, dynamic>.from(row);
        })
        .toList(growable: false);
  }
}

final class R44Session {
  final String userId;
  final String jwt;
  final String companyId;

  const R44Session(this.userId, this.jwt, this.companyId);
}

final class R44DevClient {
  static const _allowedPaths = {
    '/auth/v1/token',
    '/rest/v1/company_users',
    '/rest/v1/companies',
    '/rest/v1/drivers',
    '/rest/v1/driver_compensation_revisions',
    '/rest/v1/driver_financial_movements',
    '/rest/v1/expense_ledger_entries',
    '/rest/v1/trips',
    '/rest/v1/driver_settlements',
    '/rest/v1/driver_settlement_items',
    '/rest/v1/audit_logs',
    '/rest/v1/rpc/create_driver_settlement_draft_atomic',
  };

  final R44DevConfig config;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = r44NetworkTimeout;

  R44DevClient(this.config);

  Future<R44Reply> request(
    String method,
    String path, {
    String? jwt,
    Map<String, String>? query,
    Object? data,
  }) async {
    const postPaths = {
      '/auth/v1/token',
      '/rest/v1/driver_settlements',
      '/rest/v1/driver_settlement_items',
      '/rest/v1/rpc/create_driver_settlement_draft_atomic',
    };
    final allowed = _allowedPaths.contains(path) &&
        (method == 'GET' && !postPaths.contains(path) ||
            method == 'POST' && postPaths.contains(path) ||
            method == 'PATCH' && path == '/rest/v1/driver_settlements');
    if (!allowed) {
      throw StateError('Request outside approved Development test paths.');
    }
    final url = config.origin.resolve(path).replace(queryParameters: query);
    if (url.scheme != 'https' || url.host != r44DevHost || url.hasPort) {
      throw StateError('Non-Development request refused.');
    }
    final req = await _client.openUrl(method, url).timeout(r44NetworkTimeout);
    req.headers.set('apikey', config.key);
    req.headers.set('Accept', 'application/json');
    if (jwt != null) req.headers.set('Authorization', 'Bearer $jwt');
    if (method == 'PATCH') {
      req.headers.set('Prefer', 'return=representation');
    }
    if (data != null) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(data));
    }
    final response = await req.close().timeout(r44NetworkTimeout);
    final raw = await utf8.decoder
        .bind(response)
        .join()
        .timeout(r44NetworkTimeout);
    Object? parsed;
    try {
      parsed = raw.isEmpty ? null : jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Non-JSON Development response.');
    }
    return R44Reply(response.statusCode, parsed);
  }

  Future<R44Session> loginForRole({
    required String role,
    required String email,
    required String password,
    bool requireCompanyA = false,
  }) async {
    if (!{'owner', 'admin', 'accountant'}.contains(role)) {
      throw StateError('Only finance-role test accounts supported.');
    }
    final auth = await request(
      'POST',
      '/auth/v1/token',
      query: {'grant_type': 'password'},
      data: {'email': email, 'password': password},
    );
    final payload = auth.body;
    if (!auth.ok ||
        payload is! Map ||
        payload['access_token'] is! String ||
        payload['user'] is! Map ||
        (payload['user'] as Map)['id'] is! String) {
      throw StateError('Development test login failed.');
    }
    final jwt = payload['access_token'] as String;
    final id = (payload['user'] as Map)['id'] as String;
    if (jwt.split('.').length != 3 || !isR44Uuid(id)) {
      throw StateError('Signed test identity invalid.');
    }
    final membership = await request(
      'GET',
      '/rest/v1/company_users',
      jwt: jwt,
      query: {'select': 'company_id,role,is_active', 'user_id': 'eq.$id'},
    );
    final rows = membership.rows
        .where((row) =>
            row['is_active'] == true &&
            row['role'] == role &&
            (row['company_id'] == config.companyA ||
                row['company_id'] == config.companyB))
        .toList();
    if (rows.length != 1) {
      throw StateError('Active Development role fixture ambiguous.');
    }
    final company = rows.single['company_id'] as String;
    if (requireCompanyA && company != config.companyA) {
      throw StateError('Expected QA Company A membership.');
    }
    return R44Session(id, jwt, company);
  }

  void close() => _client.close(force: true);
}

String r44Prompt(String message) {
  stdout.write(message);
  return stdin.readLineSync()?.trim() ?? '';
}

String r44Password() {
  stdout.write('Password (hidden): ');
  final previous = stdin.echoMode;
  try {
    stdin.echoMode = false;
    return stdin.readLineSync() ?? '';
  } finally {
    stdin.echoMode = previous;
    stdout.writeln();
  }
}
