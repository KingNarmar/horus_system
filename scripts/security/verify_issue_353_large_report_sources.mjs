// #353 — disposable LOCAL Supabase Reports RPC completeness and security harness.
// No production/development URLs, no external dependencies, no credentials in git.
// Authentic access tokens are issued by the local Supabase Auth password endpoint.
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';

const companyA = '11111111-1111-4111-8111-111111111111';
const companyB = '22222222-2222-4222-8222-222222222222';
const roleEmails = Object.freeze({
  ownerA: 'horus353.owner.a@example.invalid',
  accountantA: 'horus353.accountant.a@example.invalid',
  operationsA: 'horus353.operations.a@example.invalid',
  viewerA: 'horus353.viewer.a@example.invalid',
  deactivatedA: 'horus353.deactivated.a@example.invalid',
  ownerB: 'horus353.owner.b@example.invalid',
});
const rpcNames = Object.freeze({
  operational: 'get_operational_trip_reports_source',
  expenses: 'get_trip_expenses_report_source',
  netProfit: 'get_trip_net_profit_report_source',
  invoices: 'get_open_invoices_report_source',
});

function localStatus() {
  const output = execFileSync(
    'npx',
    ['--yes', 'supabase@3.0.0', 'status', '-o', 'env'],
    { encoding: 'utf8', timeout: 120000 },
  );
  const config = {};
  for (const line of output.split(/\r?\n/)) {
    const separator = line.indexOf('=');
    if (separator < 1) continue;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    if (/^[A-Z][A-Z_]+$/.test(key)) {
      config[key] = value.replace(/^["']|["']$/g, '');
    }
  }
  return config;
}

function requireLoopbackAddress(rawUrl, label) {
  const url = new URL(rawUrl);
  assert.ok(
    ['127.0.0.1', 'localhost', '::1', '[::1]'].includes(url.hostname),
    label + ' must be a disposable LOCAL Supabase endpoint',
  );
  return url;
}

const config = localStatus();
const apiUrl = config.API_URL ?? 'http://127.0.0.1:54321';
const dbUrl = config.DB_URL ?? 'postgresql://postgres:postgres@127.0.0.1:54322/postgres';
const serviceKey = config.SERVICE_ROLE_KEY;
const anonKey = config.ANON_KEY;
requireLoopbackAddress(apiUrl, 'API_URL');
requireLoopbackAddress(dbUrl, 'DB_URL');
assert.ok(serviceKey && anonKey, 'Missing local Supabase service-role/anon keys');

async function request(url, { method = 'POST', token, body, service = false } = {}) {
  const key = service ? serviceKey : anonKey;
  const response = await fetch(url, {
    method,
    headers: {
      apikey: key,
      Authorization: 'Bearer ' + (token ?? key),
      'Content-Type': 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
    signal: AbortSignal.timeout(90000),
  });
  const content = await response.text();
  let json;
  try { json = JSON.parse(content); } catch {
    throw Error('Local endpoint returned non-JSON (HTTP ' + response.status + ')');
  }
  return { ok: response.ok, status: response.status, json };
}

function localPsql(args) {
  try {
    return execFileSync('psql', ['-X', '-v', 'ON_ERROR_STOP=1', dbUrl, ...args], {
      encoding: 'utf8', timeout: 360000, maxBuffer: 12 * 1024 * 1024,
    });
  } catch (error) {
    // Do not echo connection strings or login credentials to CI logs.
    const stderr = String(error.stderr ?? '');
    throw Error('Disposable SQL fixture failed: ' + stderr.slice(-1800));
  }
}

async function createLocalUsers() {
  const passwords = new Map();
  for (const [role, email] of Object.entries(roleEmails)) {
    const password = randomBytes(36).toString('base64url') + 'Aa1!';
    const created = await request(apiUrl + '/auth/v1/admin/users', {
      service: true,
      body: { email, password, email_confirm: true },
    });
    assert.equal(created.ok, true,
      'Local Auth fixture creation failed for ' + role + ': ' + created.status);
    assert.ok(created.json.id, 'Local Auth user ID missing for ' + role);
    passwords.set(role, password);
  }
  const tokens = new Map();
  for (const [role, email] of Object.entries(roleEmails)) {
    const signedIn = await request(apiUrl + '/auth/v1/token?grant_type=password', {
      body: { email, password: passwords.get(role) },
    });
    assert.equal(signedIn.ok, true,
      'Local Auth password login failed for ' + role + ': ' + signedIn.status);
    assert.ok(signedIn.json.access_token, 'Signed JWT missing for ' + role);
    tokens.set(role, signedIn.json.access_token);
  }
  passwords.clear();
  return tokens;
}

function countIndependentSources() {
  const sql = [
    'SELECT json_build_object(',
    "'trips', (SELECT count(*) FROM public.trips WHERE company_id='" + companyA + "'),",
    "'trip_freight', (SELECT sum(round(freight_price*100)::bigint) FROM public.trips WHERE company_id='" + companyA + "'),",
    "'expenses', (SELECT count(*) FROM public.expense_ledger_entries WHERE company_id='" + companyA + "' AND is_voided=false AND trip_id IS NOT NULL),",
    "'expense_minor', (SELECT sum(amount_minor_units) FROM public.expense_ledger_entries WHERE company_id='" + companyA + "' AND is_voided=false AND trip_id IS NOT NULL),",
    "'invoices', (SELECT count(*) FROM public.invoices WHERE company_id='" + companyA + "' AND status IN ('issued','partially_paid','paid')),",
    "'invoice_minor', (SELECT sum(total_minor_units) FROM public.invoices WHERE company_id='" + companyA + "' AND status IN ('issued','partially_paid','paid')),",
    "'payments', (SELECT count(*) FROM public.payments WHERE company_id='" + companyA + "'),",
    "'payment_minor', (SELECT sum(amount_minor_units) FROM public.payments WHERE company_id='" + companyA + "'),",
    "'other_tenant_trips', (SELECT count(*) FROM public.trips WHERE company_id='" + companyB + "')",
    ')::text;',
  ].join(' ');
  const rows = localPsql(['-A', '-t', '-c', sql]).trim();
  const counts = JSON.parse(rows);
  assert.equal(counts.trips, 1300);
  assert.equal(counts.expenses, 1300);
  assert.equal(counts.invoices, 1300);
  assert.equal(counts.payments, 1300);
  assert.equal(counts.other_tenant_trips, 23);
  return counts;
}

async function callRpc(name, companyId, token, fromDate = null, toDate = null) {
  return request(apiUrl + '/rest/v1/rpc/' + name, {
    token,
    body: {
      p_company_id: companyId,
      p_from_date: fromDate,
      p_to_date: toDate,
    },
  });
}

function assertRows(payload, key, count, idField, companyId) {
  const asOf = payload.company?.source_as_of_utc;
  assert.equal(typeof asOf, 'string', 'missing server report read time');
  assert.ok(/(?:[zZ]|[+-]\d{2}:?\d{2})$/.test(asOf), 'timestamp offset missing');
  const asOfMs = Date.parse(asOf);
  assert.ok(Number.isFinite(asOfMs), 'invalid server report time');
  assert.ok(asOfMs >= Date.now() - 120000 && asOfMs <= Date.now() + 5000,
    'report source time outside request window');
  assert.ok(Array.isArray(payload[key]), key + ' array missing');
  assert.equal(payload[key].length, count, key + ' incomplete');
  const ids = payload[key].map((row) => row[idField]);
  assert.equal(new Set(ids).size, count, key + ' duplicated IDs');
  assert.ok(ids.every((id) => typeof id === 'string' && id.length > 0));
  assert.equal(payload.company?.company_id, companyId);
}

function sumMinor(rows, property) {
  return rows.reduce((sum, row) => sum + Number(row[property]), 0);
}

async function verifyAuthorized(tokens, companyId, count, independent) {
  const owner = tokens.get(companyId === companyA ? 'ownerA' : 'ownerB');
  const returned = {};
  const errors = [];
  for (const [kind, name] of Object.entries(rpcNames)) {
    const start = performance.now();
    const outcome = await callRpc(name, companyId, owner);
    const seconds = ((performance.now() - start) / 1000).toFixed(2);
    if (!outcome.ok) {
      const reason = kind + ': HTTP ' + outcome.status +
        ', PostgreSQL code ' + String(outcome.json?.code ?? '-') +
        ', detail ' + String(outcome.json?.message ?? '-').slice(0, 110) +
        ' (' + seconds + 's)';
      console.log('SOURCE FAILURE ' + reason);
      errors.push(reason);
      continue;
    }
    returned[kind] = outcome.json;
    console.log(kind + ': verified signed-JWT response for ' + count +
      ' tenant-owned records (' + seconds + 's)');
  }

  // Even when a sibling source fails, assert the completeness of every
  // successfully returned source before failing the overall gate.
  if (returned.operational) {
    assertRows(returned.operational, 'rows', count, 'trip_id', companyId);
  }
  if (returned.expenses) {
    assertRows(returned.expenses, 'rows', count, 'expense_id', companyId);
  }
  if (returned.netProfit) {
    assertRows(returned.netProfit, 'trips', count, 'trip_id', companyId);
    assertRows(returned.netProfit, 'expenses', count, 'expense_id', companyId);
  }
  if (returned.invoices) {
    assertRows(returned.invoices, 'invoices', count, 'invoice_id', companyId);
    assertRows(returned.invoices, 'payments', count, 'payment_id', companyId);
  }
  if (independent) {
    if (returned.expenses) {
      assert.equal(sumMinor(returned.expenses.rows, 'amount_minor_units'),
        independent.expense_minor);
    }
    if (returned.netProfit) {
      assert.equal(sumMinor(returned.netProfit.trips, 'freight_minor_units'),
        independent.trip_freight);
      assert.equal(sumMinor(returned.netProfit.expenses, 'amount_minor_units'),
        independent.expense_minor);
    }
    if (returned.invoices) {
      assert.equal(sumMinor(returned.invoices.invoices, 'total_minor_units'),
        independent.invoice_minor);
      assert.equal(sumMinor(returned.invoices.payments, 'amount_minor_units'),
        independent.payment_minor);
    }
  }
  if (errors.length) {
    throw Error('Incomplete Reports sources: ' + errors.join('; '));
  }
  return returned;
}

async function verifyBoundedRange(tokens) {
  // 100 rows per business day for tenant A; three dates -> 300 source rows.
  // Tests whether the authoritative date filters reduce a large RPC enough.
  const failures = [];
  for (const [kind, name] of Object.entries(rpcNames)) {
    const start = performance.now();
    const outcome = await callRpc(
      name, companyA, tokens.get('ownerA'), '2026-11-01', '2026-11-03',
    );
    const seconds = ((performance.now() - start) / 1000).toFixed(2);
    if (!outcome.ok) {
      const message = kind + ' bounded RPC failed: HTTP ' + outcome.status +
        ', code ' + String(outcome.json?.code ?? '-');
      console.log('SOURCE FAILURE ' + message + ' (' + seconds + 's)');
      failures.push(message);
      continue;
    }
    const result = outcome.json;
    if (kind === 'operational' || kind === 'expenses') {
      assertRows(result, 'rows', 300,
        kind === 'operational' ? 'trip_id' : 'expense_id', companyA);
    } else if (kind === 'netProfit') {
      assertRows(result, 'trips', 300, 'trip_id', companyA);
      assertRows(result, 'expenses', 300, 'expense_id', companyA);
    } else {
      assertRows(result, 'invoices', 300, 'invoice_id', companyA);
      assertRows(result, 'payments', 300, 'payment_id', companyA);
    }
    console.log(kind + ': bounded date filter verified 300 rows (' +
      seconds + 's)');
  }
  return failures;
}

async function assertDenied(label, kind, companyId, token) {
  const name = rpcNames[kind];
  const outcome = await callRpc(name, companyId, token);
  assert.equal(outcome.ok, false, label + ' unexpectedly accessed ' + kind);
  // SQL-level guard must surface the stable report-denial code for
  // authenticated but unauthorized roles; anonymous denial is grant-level.
  if (token) {
    assert.equal(outcome.json.code, 'P3010', label + ' wrong denial for ' + kind);
  }
}

async function verifySnapshotRpc(tokens, original) {
  // Real signed-in users, real RLS/GRANT boundaries and 1,300 seeded rows.
  // No service-role token is used to read or create export snapshots.
  const sources = [
    ['operational', 'operational', [['rows', 'trip_id']]],
    ['expenses', 'trip_expenses', [['rows', 'expense_id']]],
    ['netProfit', 'trip_net_profit', [
      ['trips', 'trip_id'], ['expenses', 'expense_id'],
    ]],
    ['invoices', 'open_invoices', [
      ['invoices', 'invoice_id'], ['payments', 'payment_id'],
    ]],
  ];
  const owner = tokens.get('ownerA');
  for (const [key, sourceKind, streams] of sources) {
    const started = await request(
      apiUrl + '/rest/v1/rpc/start_report_export_snapshot', {
        token: owner,
        body: {
          p_company_id: companyA,
          p_source_kind: sourceKind,
          p_from_date: null,
          p_to_date: null,
        },
      },
    );
    assert.equal(started.ok, true,
      'snapshot start ' + key + ': ' + String(started.json?.code));
    const snap = started.json.snapshot_id;
    assert.ok(/^[0-9a-f-]{36}$/.test(snap));
    assert.equal(started.json.source_header.company.company_id, companyA);
    assert.equal(started.json.source_kind, sourceKind);
    assert.ok(!('rows' in started.json.source_header));
    assert.ok(!('trips' in started.json.source_header));
    assert.ok(!('payments' in started.json.source_header));

    for (const [stream, idField] of streams) {
      const expected = original[key][stream];
      assert.equal(started.json.stream_counts[stream], expected.length);
      let cursor = null;
      const rows = [];
      const pageTokens = new Set();
      for (let pageNo = 0; pageNo < 20; pageNo++) {
        const page = await request(
          apiUrl + '/rest/v1/rpc/read_report_export_snapshot_page', {
            token: owner,
            body: {
              p_snapshot_id: snap,
              p_stream: stream,
              p_cursor: cursor,
              p_page_size: 200,
            },
          },
        );
        assert.equal(page.ok, true,
          'read page ' + key + '/' + stream + ': ' + String(page.json?.code));
        assert.equal(page.json.snapshot_token, snap);
        assert.equal(page.json.total_rows, expected.length);
        assert.ok(page.json.rows.length <= 200);
        rows.push(...page.json.rows);
        cursor = page.json.next_cursor;
        if (cursor === null) break;
        assert.ok(!pageTokens.has(cursor), 'snapshot cursor repeated');
        pageTokens.add(cursor);
        if (pageNo === 19) throw Error('snapshot cursor never terminated');
      }
      assert.equal(rows.length, expected.length);
      assert.equal(new Set(rows.map(row => row[idField])).size, rows.length);
      assert.deepEqual(rows, expected,
        'Snapshot rows differ from canonical report source ' + key + '/' + stream);
      console.log('SNAPSHOT PASS ' + key + '/' + stream +
        ': ' + rows.length + ' rows over ' + (pageTokens.size + 1) + ' pages');
    }

    const malformedPage = await request(
      apiUrl + '/rest/v1/rpc/read_report_export_snapshot_page', {
        token: owner,
        body: {
          p_snapshot_id: snap, p_stream: streams[0][0],
          p_cursor: null, p_page_size: 201,
        },
      },
    );
    assert.equal(malformedPage.ok, false);
    assert.equal(malformedPage.json.code, 'P3017');

    const foreign = await request(
      apiUrl + '/rest/v1/rpc/read_report_export_snapshot_page', {
        token: tokens.get('ownerB'),
        body: {
          p_snapshot_id: snap, p_stream: streams[0][0],
          p_cursor: null, p_page_size: 10,
        },
      },
    );
    assert.equal(foreign.ok, false);
    assert.equal(foreign.json.code, 'P3017');

    const released = await request(
      apiUrl + '/rest/v1/rpc/release_report_export_snapshot', {
        token: owner, body: { p_snapshot_id: snap },
      },
    );
    assert.equal(released.json, true);
    const afterRelease = await request(
      apiUrl + '/rest/v1/rpc/read_report_export_snapshot_page', {
        token: owner,
        body: {
          p_snapshot_id: snap, p_stream: streams[0][0],
          p_cursor: null, p_page_size: 10,
        },
      },
    );
    assert.equal(afterRelease.ok, false);
    assert.equal(afterRelease.json.code, 'P3017');
  }

  for (const role of ['viewerA', 'operationsA']) {
    const denied = await request(
      apiUrl + '/rest/v1/rpc/start_report_export_snapshot', {
        token: tokens.get(role),
        body: {
          p_company_id: companyA, p_source_kind: 'trip_net_profit',
          p_from_date: null, p_to_date: null,
        },
      },
    );
    assert.equal(denied.ok, false);
    assert.equal(denied.json.code, 'P3010',
      role + ' was allowed to snapshot finance');
  }

  for (const role of ['ownerB', 'deactivatedA']) {
    const denied = await request(
      apiUrl + '/rest/v1/rpc/start_report_export_snapshot', {
        token: tokens.get(role),
        body: {
          p_company_id: companyA, p_source_kind: 'operational',
          p_from_date: null, p_to_date: null,
        },
      },
    );
    assert.equal(denied.ok, false);
    assert.equal(denied.json.code, 'P3010',
      role + ' was allowed to snapshot a forbidden tenant');
  }
  const anonymous = await request(
    apiUrl + '/rest/v1/rpc/start_report_export_snapshot', {
      body: {
        p_company_id: companyA, p_source_kind: 'operational',
        p_from_date: null, p_to_date: null,
      },
    },
  );
  assert.equal(anonymous.ok, false, 'anon exported a report');

  const finance = await request(
    apiUrl + '/rest/v1/rpc/start_report_export_snapshot', {
      token: tokens.get('accountantA'),
      body: {
        p_company_id: companyA, p_source_kind: 'trip_net_profit',
        p_from_date: null, p_to_date: null,
      },
    },
  );
  assert.equal(finance.ok, true, 'accountant should export finance');
  const accountantRelease = await request(
    apiUrl + '/rest/v1/rpc/release_report_export_snapshot', {
      token: tokens.get('accountantA'),
      body: { p_snapshot_id: finance.json.snapshot_id },
    },
  );
  assert.equal(accountantRelease.json, true);

  const expiring = await request(
    apiUrl + '/rest/v1/rpc/start_report_export_snapshot', {
      token: owner,
      body: {
        p_company_id: companyA, p_source_kind: 'operational',
        p_from_date: '2026-11-16', p_to_date: '2026-11-16',
      },
    },
  );
  assert.equal(expiring.ok, true, 'empty source snapshot failed');
  const empty = await request(
    apiUrl + '/rest/v1/rpc/read_report_export_snapshot_page', {
      token: owner,
      body: {
        p_snapshot_id: expiring.json.snapshot_id,
        p_stream: 'rows', p_cursor: null, p_page_size: 200,
      },
    },
  );
  assert.equal(empty.ok, true);
  assert.deepEqual(empty.json.rows, []);
  assert.equal(empty.json.next_cursor, null);
  assert.equal(empty.json.total_rows, 0);

  // LOCAL fixture-only expiry simulation. Never modify a hosted database.
  const expirationSql = "UPDATE private.report_export_snapshots SET " +
    "created_at = now() - interval '30 minutes', " +
    "expires_at = now() - interval '1 second' " +
    "WHERE id = '" + expiring.json.snapshot_id + "'::uuid";
  localPsql(['-c', expirationSql]);
  const expired = await request(
    apiUrl + '/rest/v1/rpc/read_report_export_snapshot_page', {
      token: owner,
      body: {
        p_snapshot_id: expiring.json.snapshot_id,
        p_stream: 'rows', p_cursor: null, p_page_size: 200,
      },
    },
  );
  assert.equal(expired.ok, false);
  assert.equal(expired.json.code, 'P3017');

  const cleaned = localPsql(['-A', '-t', '-c',
    'SELECT private.purge_expired_report_export_snapshots()',
  ]).trim();
  assert.ok(Number(cleaned) >= 1);
  console.log('PASS: bounded frozen report snapshots, JWT roles, tenants, ' +
    'expiry, invalid-page denials, release and financial source parity');
}

async function run() {
  const tokens = await createLocalUsers();
  localPsql(['-f', 'supabase/tests/issue_353_report_large_sources_fixture.sql']);

  // The selector and the write RPC must agree with the IANA canonical catalog.
  const listed = await request(apiUrl + '/rest/v1/rpc/list_company_timezones', {
    token: tokens.get('ownerA'),
    body: {},
  });
  assert.equal(listed.ok, true, 'Canonical timezone RPC must be available');
  const source = localPsql(['-A', '-t', '-c',
    "SELECT count(*) FROM pg_catalog.pg_timezone_names WHERE name IN ('Africa/Cairo','Asia/Dubai')",
  ]).trim();
  assert.equal(Number(source), 2);
  const names = listed.json.map((zone) => zone.name);
  assert.equal(names.length, 420, 'unexpected canonical timezone count');
  assert.ok(names.includes('Africa/Cairo'));
  assert.ok(names.includes('Asia/Dubai'));
  assert.ok(!names.includes('Egypt'));
  assert.ok(!names.some((zone) => zone.startsWith('posix/') ||
    zone.startsWith('right/')));
  const forbidden = await request(
    apiUrl + '/rest/v1/rpc/update_company_business_timezone', {
      token: tokens.get('ownerA'),
      body: { p_company_id: companyA, p_business_timezone: 'Egypt' },
    },
  );
  assert.equal(forbidden.ok, false, 'legacy alias must not be newly saved');
  assert.equal(forbidden.json.code, 'P2604');

  const independent = countIndependentSources();
  // Bulk fixture inserts need planner statistics, just as a long-lived
  // production table receives from auto-analyze. Keep every real RLS rule.
  localPsql(['-c', 'ANALYZE public.expense_ledger_entries; ' +
    'ANALYZE public.expense_types; ANALYZE public.trips; ' +
    'ANALYZE public.customers; ANALYZE public.routes;']);
  const boundedFailures = await verifyBoundedRange(tokens);
  const original = await verifyAuthorized(
    tokens, companyA, independent.trips, independent,
  );
  await verifySnapshotRpc(tokens, original);
  await verifyAuthorized(tokens, companyB, independent.other_tenant_trips);

  for (const kind of Object.keys(rpcNames)) {
    await assertDenied('foreign tenant B->A', kind, companyA, tokens.get('ownerB'));
    await assertDenied('deactivated membership', kind, companyA, tokens.get('deactivatedA'));
    await assertDenied('anonymous', kind, companyA, undefined);
  }
  for (const role of ['operationsA', 'viewerA']) {
    const operational = await callRpc(rpcNames.operational, companyA, tokens.get(role));
    assert.equal(operational.ok, true, role + ' operational reporting denied');
    assertRows(operational.json, 'rows', independent.trips, 'trip_id', companyA);
    for (const kind of ['expenses', 'netProfit', 'invoices']) {
      await assertDenied(role, kind, companyA, tokens.get(role));
    }
  }
  const accountant = await callRpc(rpcNames.netProfit, companyA, tokens.get('accountantA'));
  assert.equal(accountant.ok, true, 'Accountant must see authorized net profit');
  assertRows(accountant.json, 'trips', independent.trips, 'trip_id', companyA);

  for (const kind of Object.keys(rpcNames)) {
    const emptyRange = await callRpc(rpcNames[kind], companyA,
      tokens.get('ownerA'), '2026-11-16', '2026-11-16');
    assert.equal(emptyRange.ok, true, kind + ' filtered request failed');
    const root = emptyRange.json;
    for (const key of ['rows', 'trips', 'expenses', 'invoices', 'payments']) {
      if (Array.isArray(root[key])) assert.equal(root[key].length, 0);
    }
  }
  assert.deepEqual(boundedFailures, [], 'Bounded date-range source failures');
  console.log('PASS: four source RPCs, independent row/amount totals, ' +
    'signed-JWT role and tenant isolation, date filters and >1000-row responses');

  // Optional independent CI job: only local loopback database and signed JWTs.
  // Never run large synthetic fixture writes on a hosted Supabase project.
  if (process.env.HORUS_353_STRESS === '1') {
    const { verifyIssue353Stress } = await import(
      './verify_issue_353_snapshot_stress.mjs'
    );
    await verifyIssue353Stress({
      tokens, localPsql, request, apiUrl, companyA, companyB,
    });
  }
}

run().catch((error) => {
  console.error('FAIL: Issue 353 isolated report source check: ' + error.message);
  process.exitCode = 1;
});
