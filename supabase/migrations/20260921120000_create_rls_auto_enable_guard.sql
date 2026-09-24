-- Issue #197: make the existing public-schema RLS auto-enable guard
-- reproducible for fresh Supabase environments.
--
-- The development database already has the ensure_rls event trigger. Issue #243
-- later hardens this infrastructure-only SECURITY DEFINER function by revoking
-- API-role execution. This migration restores the missing creation step.

BEGIN;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  command_row record;
BEGIN
  FOR command_row IN
    SELECT *
    FROM pg_catalog.pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table', 'partitioned table')
  LOOP
    IF command_row.schema_name = 'public' THEN
      BEGIN
        EXECUTE pg_catalog.format(
          'ALTER TABLE IF EXISTS %s ENABLE ROW LEVEL SECURITY',
          command_row.object_identity
        );
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG
            'rls_auto_enable: failed to enable RLS on %',
            command_row.object_identity;
      END;
    END IF;
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION public.rls_auto_enable()
FROM PUBLIC, anon, authenticated, service_role;

DROP EVENT TRIGGER IF EXISTS ensure_rls;

CREATE EVENT TRIGGER ensure_rls
ON ddl_command_end
WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
EXECUTE FUNCTION public.rls_auto_enable();

COMMIT;
