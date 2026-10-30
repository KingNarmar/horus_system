-- #345 operator-side preflight (read-only, before first mutation).
-- Must be connected to the existing Production project via verified host and user.
DO $gate$
DECLARE migrations integer;
BEGIN
  SELECT count(*) INTO migrations FROM supabase_migrations.schema_migrations;
  IF migrations<>123
     OR (SELECT max(version) FROM supabase_migrations.schema_migrations)<>'20261012175344'
     OR (SELECT count(*) FROM auth.users)<>5
     OR (SELECT count(*) FROM public.companies)<>1
     OR (SELECT count(*) FROM storage.objects)<>0
     OR (SELECT count(*) FROM storage.buckets WHERE id IN ('business-documents','driver-documents') AND NOT public)<>2
     OR (SELECT count(*) FROM private.company_invitation_confirmation_keys)<>1
     OR (SELECT count(*) FROM pg_policies WHERE schemaname='realtime' AND tablename='messages' AND policyname LIKE 'horus_%')<>1
  THEN
    RAISE EXCEPTION 'Production cutover pre-impact state changed. Abort and review.';
  END IF;
  IF (SELECT count(*) FROM cron.job WHERE jobname='horus-account-deletion-finalizer'
      AND schedule='17 * * * *')<>1
  THEN
    RAISE EXCEPTION 'Expected account-deletion Cron record missing or changed';
  END IF;
END $gate$;
