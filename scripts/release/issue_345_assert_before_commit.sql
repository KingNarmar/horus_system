-- #345 — run in SAME transaction AFTER app schema, managed policies,
-- original Production invitation key, Auth/ensure_rls guards and reference seed.
-- Raises on any structural or accidental data-copy discrepancy.
DO $verify$
DECLARE bad_tables integer; table_row record; row_count bigint;
BEGIN
  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON c.relnamespace=n.oid
      WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p'))<>37
     OR (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid
          WHERE n.nspname IN ('public','private') AND p.prokind='f')<>137
     OR (SELECT count(*) FROM pg_trigger t JOIN pg_class c ON t.tgrelid=c.oid
          JOIN pg_namespace n ON c.relnamespace=n.oid
          WHERE n.nspname IN ('public','private') AND NOT t.tgisinternal)<>70
     OR (SELECT count(*) FROM pg_policies WHERE schemaname='public')<>74
     OR (SELECT count(*) FROM pg_policies WHERE schemaname='storage' AND tablename='objects'
           AND (policyname LIKE 'business_documents_%' OR policyname LIKE 'driver_documents_%'))<>13
     OR (SELECT count(*) FROM pg_policies WHERE schemaname='realtime' AND tablename='messages'
           AND policyname LIKE 'horus_%')<>15
  THEN
    RAISE EXCEPTION 'Issue #345 expected schema/RLS/trigger parity FAILED';
  END IF;

  IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON c.relnamespace=n.oid
      WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
       AND NOT c.relrowsecurity)<>0
  THEN RAISE EXCEPTION 'A H.O.R.U.S table lacks RLS'; END IF;

  IF (SELECT count(*) FROM private.company_invitation_confirmation_keys)<>1
     OR (SELECT count(*) FROM pg_temp.horus345_prod_invitation_key)<>1
     OR NOT EXISTS (
       SELECT 1 FROM private.company_invitation_confirmation_keys k
       JOIN pg_temp.horus345_prod_invitation_key original USING (singleton)
       WHERE k.key_hash=original.key_hash AND octet_length(k.key_hash)=32
     )
  THEN RAISE EXCEPTION 'Production invitation key was not preserved'; END IF;

  IF (SELECT count(*) FROM public.subscription_plans)<>3
     OR (SELECT string_agg(code,',' ORDER BY code) FROM public.subscription_plans)
        <> 'basic,enterprise,pro'
  THEN RAISE EXCEPTION 'Unexpected subscription reference plans'; END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_event_trigger WHERE evtname='ensure_rls' AND evtenabled='O')
     OR NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname='on_auth_user_created_create_profile'
                    AND tgrelid='auth.users'::regclass AND tgenabled='O')
  THEN RAISE EXCEPTION 'Auth profile or RLS event trigger missing'; END IF;

  IF (SELECT count(*) FROM storage.buckets WHERE id IN ('business-documents','driver-documents') AND NOT public)<>2
     OR (SELECT count(*) FROM storage.objects)<>0
  THEN RAISE EXCEPTION 'Production private Storage buckets/objects drift'; END IF;

  -- Every company-owned/test/financial record must be absent.
  FOR table_row IN
    SELECT n.nspname AS s,c.relname AS t
    FROM pg_class c JOIN pg_namespace n ON c.relnamespace=n.oid
    WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p')
      AND NOT (n.nspname='public' AND c.relname='subscription_plans')
      AND NOT (n.nspname='private' AND c.relname='company_invitation_confirmation_keys')
  LOOP
    EXECUTE format('SELECT count(*) FROM %I.%I',table_row.s,table_row.t)
      INTO row_count;
    IF row_count<>0 THEN RAISE EXCEPTION 'Unexpected business data in %.%',table_row.s,table_row.t; END IF;
  END LOOP;
END $verify$;
