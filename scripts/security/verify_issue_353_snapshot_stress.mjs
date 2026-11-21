// #353 stress assertions run ONLY through the disposable loopback harness.
// Never accepts hosted URLs or service-role data access from a Flutter client.
import assert from 'node:assert/strict';

const expectedRows = 12000;
const pageSize = 200;
const maxPageBytes = 1024 * 1024;
const sourceDefinitions = [
  ['operational', [['rows', 'trip_id']]],
  ['trip_expenses', [['rows', 'expense_id', 'amount_minor_units']]],
  ['trip_net_profit', [
    ['trips', 'trip_id', 'freight_minor_units'],
    ['expenses', 'expense_id', 'amount_minor_units'],
  ]],
  ['open_invoices', [
    ['invoices', 'invoice_id', 'total_minor_units'],
    ['payments', 'payment_id', 'amount_minor_units'],
  ]],
];

function assertUuid(value) {
  assert.match(value, /^[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i);
  return value;
}

function aggregateStats(localPsql, companyA, companyB) {
  const query = `SELECT pg_catalog.json_build_object(
    'trips', (SELECT count(*) FROM public.trips WHERE company_id='${companyA}'),
    'freight', (SELECT sum(round(freight_price*100)::bigint)
      FROM public.trips WHERE company_id='${companyA}'),
    'expenses', (SELECT count(*) FROM public.expense_ledger_entries
      WHERE company_id='${companyA}' AND is_voided=false AND trip_id IS NOT NULL),
    'expense_minor', (SELECT sum(amount_minor_units)
      FROM public.expense_ledger_entries WHERE company_id='${companyA}'
      AND is_voided=false AND trip_id IS NOT NULL),
    'invoices', (SELECT count(*) FROM public.invoices
      WHERE company_id='${companyA}' AND status IN ('issued','partially_paid','paid')),
    'invoice_minor', (SELECT sum(total_minor_units) FROM public.invoices
      WHERE company_id='${companyA}' AND status IN ('issued','partially_paid','paid')),
    'payments', (SELECT count(*) FROM public.payments
      WHERE company_id='${companyA}'),
    'payment_minor', (SELECT sum(amount_minor_units) FROM public.payments
      WHERE company_id='${companyA}'),
    'other_tenant_trips', (SELECT count(*) FROM public.trips
      WHERE company_id='${companyB}')
  )::text;`;
  const stats = JSON.parse(localPsql(['-A', '-t', '-c', query]).trim());
  for (const key of ['trips', 'expenses', 'invoices', 'payments']) {
    assert.equal(stats[key], expectedRows, key + ' stress seed incomplete');
  }
  assert.equal(stats.other_tenant_trips, 23);
  return stats;
}

async function rpc(request, apiUrl, name, token, body) {
  return request(apiUrl + '/rest/v1/rpc/' + name, { token, body });
}

async function testFrozenRows({localPsql, request, apiUrl, token, snapshotId, page}) {
  const before = page.rows;
  assert.ok(before.length > 0);
  const tripId = assertUuid(before[0].trip_id);
  const companyId = assertUuid(before[0].company_id ?? '11111111-1111-4111-8111-111111111111');
  // Only synthetic data in a disposable local DB; the snapshot must not change.
  const sql = `UPDATE public.trips
    SET loading_location = 'MUTATED_AFTER_SNAPSHOT'
    WHERE id = '${tripId}'::uuid AND company_id = '${companyId}'::uuid;`;
  localPsql(['-c', sql]);
  try {
    const later = await rpc(request, apiUrl, 'read_report_export_snapshot_page',
      token, {
        p_snapshot_id: snapshotId, p_stream: 'rows',
        p_cursor: null, p_page_size: pageSize,
      });
    assert.equal(later.ok, true, 'frozen page reload failed');
    assert.deepEqual(later.json.rows, before,
      'snapshot rows changed after live trip update');
  } finally {
    localPsql(['-c', `UPDATE public.trips SET loading_location = 'Origin A'
      WHERE id = '${tripId}'::uuid AND company_id = '${companyId}'::uuid;`]);
  }
}

async function verifyLivePermissionRecheck({localPsql, request, apiUrl, tokens, companyA}) {
  const accountant = tokens.get('accountantA');
  const started = await rpc(request, apiUrl, 'start_report_export_snapshot',
    accountant, {
      p_company_id: companyA, p_source_kind: 'trip_net_profit',
      p_from_date: '2026-11-16', p_to_date: '2026-11-16',
    });
  assert.equal(started.ok, true, 'finance pre-revocation start failed');
  const id = assertUuid(started.json.snapshot_id);
  const update = (role) => localPsql(['-c', `UPDATE public.company_users
    SET role='${role}'::public.company_role
    WHERE company_id='${companyA}'::uuid
    AND user_id=(SELECT id FROM auth.users
      WHERE email='horus353.accountant.a@example.invalid');`]);
  update('viewer');
  try {
    const blocked = await rpc(request, apiUrl,
      'read_report_export_snapshot_page', accountant, {
        p_snapshot_id: id, p_stream: 'trips',
        p_cursor: null, p_page_size: pageSize,
      });
    assert.equal(blocked.ok, false,
      'downgraded accountant read frozen financial source');
    assert.equal(blocked.json.code, 'P3010',
      'role downgrade must be checked on every page');
  } finally {
    update('accountant');
    const released = await rpc(request, apiUrl,
      'release_report_export_snapshot', accountant, { p_snapshot_id: id });
    assert.equal(released.json, true);
  }
}

async function verifyActiveBudget({request, apiUrl, tokens, companyA}) {
  const token = tokens.get('ownerA');
  const active = [];
  try {
    for (let i = 0; i < 3; i++) {
      const started = await rpc(request, apiUrl,
        'start_report_export_snapshot', token, {
          p_company_id: companyA, p_source_kind: 'operational',
          p_from_date: '2026-11-16', p_to_date: '2026-11-16',
        });
      assert.equal(started.ok, true, 'budget seed snapshot failed');
      active.push(assertUuid(started.json.snapshot_id));
    }
    const over = await rpc(request, apiUrl, 'start_report_export_snapshot',
      token, {
        p_company_id: companyA, p_source_kind: 'operational',
        p_from_date: '2026-11-16', p_to_date: '2026-11-16',
      });
    assert.equal(over.ok, false, 'fourth snapshot exceeded active budget');
    assert.equal(over.json.code, 'P3015');
  } finally {
    for (const id of active) {
      const released = await rpc(request, apiUrl,
        'release_report_export_snapshot', token, { p_snapshot_id: id });
      assert.equal(released.json, true);
    }
  }
}

export async function verifyIssue353Stress({
  tokens, localPsql, request, apiUrl, companyA, companyB,
}) {
  // The base 1,300 case already passed before this optional workload runs.
  localPsql(['-f', 'supabase/tests/issue_353_report_12k_stress_fixture.sql']);
  localPsql(['-c', 'ANALYZE public.trips; ANALYZE public.expense_ledger_entries; ' +
    'ANALYZE public.invoices; ANALYZE public.payments;']);
  const stats = aggregateStats(localPsql, companyA, companyB);
  const owner = tokens.get('ownerA');

  for (const [sourceKind, streams] of sourceDefinitions) {
    const startMs = performance.now();
    const started = await rpc(request, apiUrl, 'start_report_export_snapshot',
      owner, {
        p_company_id: companyA, p_source_kind: sourceKind,
        p_from_date: null, p_to_date: null,
      });
    assert.equal(started.ok, true,
      sourceKind + ' 12k start failure: ' + String(started.json?.code));
    const snapshotId = assertUuid(started.json.snapshot_id);
    let peakPageBytes = 0;
    let totalPages = 0;

    try {
      const initializationMs = Math.round(performance.now() - startMs);
      const bytes = Number(localPsql(['-A', '-t', '-c',
        `SELECT source_bytes FROM private.report_export_snapshots
        WHERE id='${snapshotId}'::uuid;`,
      ]).trim());
      assert.ok(bytes > 0 && bytes <= 67108864);
      assert.equal(started.json.source_header.company.company_id, companyA);

      for (const [stream, idField, amountField] of streams) {
        assert.equal(started.json.stream_counts[stream], expectedRows,
          sourceKind + '/' + stream + ' incomplete server count');
        const ids = new Set();
        let cursor = null;
        let total = 0;
        let sum = 0;
        let pages = 0;
        do {
          const page = await rpc(request, apiUrl,
            'read_report_export_snapshot_page', owner, {
              p_snapshot_id: snapshotId, p_stream: stream,
              p_cursor: cursor, p_page_size: pageSize,
            });
          assert.equal(page.ok, true,
            sourceKind + '/' + stream + ' page: ' + String(page.json?.code));
          assert.equal(page.json.snapshot_token, snapshotId);
          assert.equal(page.json.stream, stream);
          assert.equal(page.json.total_rows, expectedRows);
          assert.ok(page.json.rows.length > 0 &&
            page.json.rows.length <= pageSize);
          const pageBytes = Buffer.byteLength(JSON.stringify(page.json), 'utf8');
          peakPageBytes = Math.max(peakPageBytes, pageBytes);
          assert.ok(pageBytes <= maxPageBytes,
            sourceKind + '/' + stream + ' response exceeded 1 MiB');
          for (const row of page.json.rows) {
            assert.ok(row[idField] && !ids.has(row[idField]),
              sourceKind + '/' + stream + ' duplicate or missing ID');
            ids.add(row[idField]);
            if (amountField) {
              assert.ok(Number.isSafeInteger(row[amountField]));
              sum += row[amountField];
            }
          }
          if (sourceKind === 'operational' && pages === 0) {
            await testFrozenRows({
              localPsql, request, apiUrl, token: owner, snapshotId,
              page: page.json,
            });
          }
          total += page.json.rows.length;
          cursor = page.json.next_cursor;
          pages++;
          assert.ok(pages <= Math.ceil(expectedRows / pageSize),
            'snapshot cursor did not terminate');
        } while (cursor !== null);
        assert.equal(total, expectedRows,
          sourceKind + '/' + stream + ' truncated');
        if (amountField) {
          const expectedAmount = ({
            'trip_net_profit/trips': stats.freight,
            'trip_net_profit/expenses': stats.expense_minor,
            'trip_expenses/rows': stats.expense_minor,
            'open_invoices/invoices': stats.invoice_minor,
            'open_invoices/payments': stats.payment_minor,
          })[sourceKind + '/' + stream];
          assert.equal(sum, expectedAmount,
            sourceKind + '/' + stream + ' monetary precision changed');
        }
        totalPages += pages;
      }
      const elapsedMs = Math.round(performance.now() - startMs);
      console.log('STRESS VERIFIED ' + JSON.stringify({
        sourceKind, rowsPerStream: expectedRows, totalPages,
        sourceBytes: bytes, peakPageBytes, initializationMs, elapsedMs,
      }));
    } finally {
      const released = await rpc(request, apiUrl,
        'release_report_export_snapshot', owner, {
          p_snapshot_id: snapshotId,
        });
      assert.equal(released.json, true, 'stress snapshot leaked');
    }
  }

  await verifyLivePermissionRecheck({
    localPsql, request, apiUrl, tokens, companyA,
  });
  await verifyActiveBudget({request, apiUrl, tokens, companyA});
  const leaked = Number(localPsql(['-A', '-t', '-c',
    `SELECT count(*) FROM private.report_export_snapshots
      WHERE company_id='${companyA}'::uuid;`,
  ]).trim());
  assert.equal(leaked, 0, 'stress left active export snapshots');
  console.log('PASS: 12,000 rows/source, frozen data, bounded pages, ' +
    'exact totals, live role recheck, capacity and cleanup');
}
