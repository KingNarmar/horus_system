-- H.O.R.U.S #353: immutable, company-scoped, short-lived report export snapshots.
-- Keeps existing four authoritative report RPCs as the source of truth.
-- All page reads are bounded and address only server-frozen private rows.
-- Note: snapshot creation still materializes ONE bounded-size source JSON
-- inside Postgres. Load testing must validate its memory/latency budget.
BEGIN;

CREATE TABLE private.report_export_snapshots (
  id uuid PRIMARY KEY DEFAULT pg_catalog.gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  actor_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_kind text NOT NULL CHECK (source_kind IN (
    'operational', 'trip_expenses', 'trip_net_profit', 'open_invoices'
  )),
  source_header jsonb NOT NULL,
  stream_counts jsonb NOT NULL,
  source_bytes bigint NOT NULL CHECK (source_bytes >= 0),
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  expires_at timestamptz NOT NULL,
  UNIQUE (id, company_id),
  CHECK (expires_at > created_at)
);
CREATE INDEX report_export_snapshots_expiry_idx
  ON private.report_export_snapshots(expires_at);
CREATE INDEX report_export_snapshots_actor_idx
  ON private.report_export_snapshots(actor_user_id, expires_at);

CREATE TABLE private.report_export_snapshot_rows (
  snapshot_id uuid NOT NULL,
  company_id uuid NOT NULL,
  stream text NOT NULL,
  row_position bigint NOT NULL CHECK (row_position > 0),
  row_id text NOT NULL CHECK (pg_catalog.btrim(row_id) <> ''),
  row_data jsonb NOT NULL,
  page_token uuid NOT NULL DEFAULT pg_catalog.gen_random_uuid(),
  PRIMARY KEY (snapshot_id, stream, row_position),
  UNIQUE (snapshot_id, stream, row_id),
  UNIQUE (snapshot_id, stream, page_token),
  FOREIGN KEY (snapshot_id, company_id)
    REFERENCES private.report_export_snapshots(id, company_id) ON DELETE CASCADE
);
CREATE INDEX report_export_snapshot_rows_company_idx
  ON private.report_export_snapshot_rows(company_id, snapshot_id);

ALTER TABLE private.report_export_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.report_export_snapshot_rows ENABLE ROW LEVEL SECURITY;
-- No client policies/grants; access only through reviewed SECURITY DEFINER RPCs.
REVOKE ALL ON private.report_export_snapshots
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON private.report_export_snapshot_rows
  FROM PUBLIC, anon, authenticated, service_role;

CREATE FUNCTION public.start_report_export_snapshot(
  p_company_id uuid,
  p_source_kind text,
  p_from_date date,
  p_to_date date
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $snapshot_start$
DECLARE
  v_actor uuid := auth.uid();
  v_role text;
  v_snapshot_id uuid := pg_catalog.gen_random_uuid();
  v_payload jsonb;
  v_header jsonb;
  v_rows jsonb;
  v_streams text[];
  v_stream text;
  v_id_field text;
  v_counts jsonb := '{}'::jsonb;
  v_total bigint := 0;
  v_bytes bigint;
  v_active integer;
  v_expiry timestamptz;
  v_max_rows CONSTANT bigint := 50000;
  v_max_bytes CONSTANT bigint := 67108864;
  v_max_active CONSTANT integer := 3;
  v_ttl CONSTANT interval := interval '15 minutes';
BEGIN
  IF v_actor IS NULL OR p_company_id IS NULL
     OR p_source_kind IS NULL
     OR p_source_kind NOT IN (
       'operational', 'trip_expenses', 'trip_net_profit', 'open_invoices'
     ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3010',
      MESSAGE = 'reports_permission_denied';
  END IF;
  IF p_from_date IS NOT NULL AND p_to_date IS NOT NULL
     AND p_from_date > p_to_date THEN
    RAISE EXCEPTION USING ERRCODE = 'P3011',
      MESSAGE = 'reports_invalid_date_range';
  END IF;

  -- Serializes same-user starts, preventing parallel quota bypass.
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_actor::text, 353)
  );

  SELECT cu.role::text INTO v_role
  FROM public.company_users cu
  JOIN public.companies co ON co.id = cu.company_id
  WHERE cu.user_id = v_actor
    AND cu.company_id = p_company_id
    AND cu.is_active = true
    AND co.is_active = true
  FOR SHARE OF cu, co;
  IF NOT FOUND OR (
    p_source_kind = 'operational'
      AND v_role NOT IN ('owner', 'admin', 'operations', 'accountant', 'viewer')
  ) OR (
    p_source_kind <> 'operational'
      AND v_role NOT IN ('owner', 'admin', 'accountant')
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3010',
      MESSAGE = 'reports_permission_denied';
  END IF;

  -- Expired work is purged even when the scheduler is temporarily unavailable.
  DELETE FROM private.report_export_snapshots
  WHERE actor_user_id = v_actor AND expires_at <= pg_catalog.now();
  SELECT pg_catalog.count(*) INTO v_active
  FROM private.report_export_snapshots
  WHERE actor_user_id = v_actor AND expires_at > pg_catalog.now();
  IF v_active >= v_max_active THEN
    RAISE EXCEPTION USING ERRCODE = 'P3015',
      MESSAGE = 'reports_export_capacity_reached';
  END IF;

  -- Invoke exactly once, in the same statement/read snapshot as both
  -- financial streams and all validation counters. Never re-read per page.
  v_payload := CASE p_source_kind
    WHEN 'operational' THEN
      public.get_operational_trip_reports_source(
        p_company_id, p_from_date, p_to_date
      )
    WHEN 'trip_expenses' THEN
      public.get_trip_expenses_report_source(
        p_company_id, p_from_date, p_to_date
      )
    WHEN 'trip_net_profit' THEN
      public.get_trip_net_profit_report_source(
        p_company_id, p_from_date, p_to_date
      )
    WHEN 'open_invoices' THEN
      public.get_open_invoices_report_source(
        p_company_id, p_from_date, p_to_date
      )
  END;
  IF v_payload IS NULL OR pg_catalog.jsonb_typeof(v_payload) <> 'object'
     OR pg_catalog.jsonb_typeof(v_payload->'company') <> 'object'
     OR v_payload->'company'->>'company_id' IS DISTINCT FROM p_company_id::text
  THEN
    RAISE EXCEPTION USING ERRCODE = 'P3016',
      MESSAGE = 'reports_export_snapshot_invalid';
  END IF;

  v_streams := CASE p_source_kind
    WHEN 'operational' THEN ARRAY['rows']::text[]
    WHEN 'trip_expenses' THEN ARRAY['rows']::text[]
    WHEN 'trip_net_profit' THEN ARRAY['trips','expenses']::text[]
    WHEN 'open_invoices' THEN ARRAY['invoices','payments']::text[]
  END;
  -- Bound the UTF-8 JSON serialization, not a potentially compressed
  -- PostgreSQL internal storage representation.
  v_bytes := pg_catalog.octet_length(v_payload::text);
  v_header := v_payload;
  FOREACH v_stream IN ARRAY v_streams LOOP
    v_rows := v_payload -> v_stream;
    IF pg_catalog.jsonb_typeof(v_rows) <> 'array' THEN
      RAISE EXCEPTION USING ERRCODE = 'P3016',
        MESSAGE = 'reports_export_snapshot_invalid';
    END IF;
    v_total := v_total + pg_catalog.jsonb_array_length(v_rows);
    v_counts := v_counts || pg_catalog.jsonb_build_object(
      v_stream, pg_catalog.jsonb_array_length(v_rows)
    );
    v_header := v_header - v_stream;
  END LOOP;
  -- Explicit resource failures; never truncate or silently reduce dates.
  IF v_total > v_max_rows OR v_bytes > v_max_bytes THEN
    RAISE EXCEPTION USING ERRCODE = 'P3015',
      MESSAGE = 'reports_export_capacity_reached';
  END IF;

  v_expiry := pg_catalog.now() + v_ttl;
  INSERT INTO private.report_export_snapshots (
    id, company_id, actor_user_id, source_kind,
    source_header, stream_counts, source_bytes, expires_at
  ) VALUES (
    v_snapshot_id, p_company_id, v_actor, p_source_kind,
    v_header, v_counts, v_bytes, v_expiry
  );
  FOREACH v_stream IN ARRAY v_streams LOOP
    v_id_field := CASE v_stream
      WHEN 'rows' THEN CASE p_source_kind
        WHEN 'operational' THEN 'trip_id' ELSE 'expense_id' END
      WHEN 'trips' THEN 'trip_id'
      WHEN 'expenses' THEN 'expense_id'
      WHEN 'invoices' THEN 'invoice_id'
      WHEN 'payments' THEN 'payment_id'
    END;
    INSERT INTO private.report_export_snapshot_rows (
      snapshot_id, company_id, stream, row_position, row_id, row_data
    )
    SELECT v_snapshot_id, p_company_id, v_stream, source.ordinality,
           source.value ->> v_id_field, source.value
    FROM pg_catalog.jsonb_array_elements(v_payload -> v_stream)
         WITH ORDINALITY AS source(value, ordinality);
  END LOOP;

  RETURN pg_catalog.jsonb_build_object(
    'snapshot_id', v_snapshot_id,
    'snapshot_token', v_snapshot_id::text,
    'source_kind', p_source_kind,
    'source_header', v_header,
    'stream_counts', v_counts,
    'expires_at', v_expiry
  );
END;
$snapshot_start$;

CREATE FUNCTION public.read_report_export_snapshot_page(
  p_snapshot_id uuid,
  p_stream text,
  p_cursor uuid,
  p_page_size integer
)
RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $snapshot_read$
DECLARE
  v_actor uuid := auth.uid();
  v_snapshot private.report_export_snapshots%ROWTYPE;
  v_from_position bigint := 0;
  v_total bigint;
  v_count bigint;
  v_last_position bigint;
  v_next_cursor uuid;
  v_rows jsonb;
  v_page_limit CONSTANT integer := 200;
BEGIN
  IF v_actor IS NULL OR p_page_size IS NULL
     OR p_page_size < 1 OR p_page_size > v_page_limit
     OR p_stream IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P3017',
      MESSAGE = 'reports_export_page_invalid';
  END IF;
  SELECT * INTO v_snapshot
  FROM private.report_export_snapshots
  WHERE id = p_snapshot_id
    AND actor_user_id = v_actor
    AND expires_at > pg_catalog.now();
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P3017',
      MESSAGE = 'reports_export_page_invalid';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.company_users cu
    JOIN public.companies co ON co.id = cu.company_id
    WHERE cu.company_id = v_snapshot.company_id
      AND cu.user_id = v_actor AND cu.is_active = true AND co.is_active = true
      AND (
        (v_snapshot.source_kind = 'operational'
          AND cu.role IN (
            'owner'::public.company_role, 'admin'::public.company_role,
            'operations'::public.company_role,
            'accountant'::public.company_role,
            'viewer'::public.company_role
          ))
        OR
        (v_snapshot.source_kind <> 'operational'
          AND cu.role IN (
            'owner'::public.company_role, 'admin'::public.company_role,
            'accountant'::public.company_role
          ))
      )
  ) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3010',
      MESSAGE = 'reports_permission_denied';
  END IF;
  IF NOT (v_snapshot.stream_counts ? p_stream) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3017',
      MESSAGE = 'reports_export_page_invalid';
  END IF;
  v_total := (v_snapshot.stream_counts ->> p_stream)::bigint;
  IF p_cursor IS NOT NULL THEN
    SELECT row_position INTO v_from_position
    FROM private.report_export_snapshot_rows
    WHERE snapshot_id = p_snapshot_id
      AND company_id = v_snapshot.company_id
      AND stream = p_stream AND page_token = p_cursor;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE = 'P3017',
        MESSAGE = 'reports_export_page_invalid';
    END IF;
  END IF;

  SELECT pg_catalog.count(*),
         pg_catalog.max(page.row_position),
         coalesce(pg_catalog.jsonb_agg(
           page.row_data ORDER BY page.row_position
         ), '[]'::jsonb)
  INTO v_count, v_last_position, v_rows
  FROM (
    SELECT row_position, row_data
    FROM private.report_export_snapshot_rows
    WHERE snapshot_id = p_snapshot_id
      AND company_id = v_snapshot.company_id
      AND stream = p_stream
      AND row_position > v_from_position
    ORDER BY row_position
    LIMIT p_page_size
  ) AS page;

  IF v_from_position + v_count > v_total
     OR (v_count = 0 AND v_from_position < v_total) THEN
    RAISE EXCEPTION USING ERRCODE = 'P3016',
      MESSAGE = 'reports_export_snapshot_invalid';
  END IF;
  IF v_from_position + v_count < v_total THEN
    SELECT page_token INTO v_next_cursor
    FROM private.report_export_snapshot_rows
    WHERE snapshot_id = p_snapshot_id AND stream = p_stream
      AND company_id = v_snapshot.company_id
      AND row_position = v_last_position;
    IF NOT FOUND THEN
      RAISE EXCEPTION USING ERRCODE = 'P3016',
        MESSAGE = 'reports_export_snapshot_invalid';
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'snapshot_token', v_snapshot.id::text,
    'stream', p_stream,
    'total_rows', v_total,
    'rows', v_rows,
    'next_cursor', v_next_cursor
  );
END;
$snapshot_read$;

CREATE FUNCTION public.release_report_export_snapshot(p_snapshot_id uuid)
RETURNS boolean
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $snapshot_release$
DECLARE
  v_count bigint;
BEGIN
  IF auth.uid() IS NULL OR p_snapshot_id IS NULL THEN
    RETURN false;
  END IF;
  DELETE FROM private.report_export_snapshots
  WHERE id = p_snapshot_id AND actor_user_id = auth.uid();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count > 0;
END;
$snapshot_release$;

CREATE FUNCTION private.purge_expired_report_export_snapshots()
RETURNS integer
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $snapshot_purge$
DECLARE
  v_count integer;
BEGIN
  DELETE FROM private.report_export_snapshots
  WHERE expires_at <= pg_catalog.now();
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$snapshot_purge$;

REVOKE ALL ON FUNCTION public.start_report_export_snapshot(uuid,text,date,date)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.read_report_export_snapshot_page(uuid,text,uuid,integer)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION public.release_report_export_snapshot(uuid)
  FROM PUBLIC, anon, authenticated, service_role;
REVOKE ALL ON FUNCTION private.purge_expired_report_export_snapshots()
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.start_report_export_snapshot(uuid,text,date,date)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.read_report_export_snapshot_page(uuid,text,uuid,integer)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.release_report_export_snapshot(uuid)
  TO authenticated;

-- Server-only expiry enforcement; rows cascade when the parent is deleted.
-- Abort on unexpected pre-existing job, never silently overwrite it.
DO $snapshot_cron$
BEGIN
  IF EXISTS (
    SELECT 1 FROM cron.job
    WHERE jobname = 'horus-report-export-snapshot-cleanup'
  ) THEN
    RAISE EXCEPTION 'report_export_cleanup_job_already_exists';
  END IF;
  PERFORM cron.schedule(
    'horus-report-export-snapshot-cleanup',
    '*/5 * * * *',
    'SELECT private.purge_expired_report_export_snapshots();'
  );
END;
$snapshot_cron$;

COMMIT;
