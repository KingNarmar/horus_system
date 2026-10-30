-- #345: run AFTER public/private schema and managed Storage/Realtime policy restore,
-- but BEFORE COMMIT of the SAME Production psql session/transaction.
-- Production secret itself is NEVER copied from Development.
DO $$
BEGIN
  IF to_regclass('pg_temp.horus345_prod_invitation_key') IS NULL
     OR to_regclass('private.company_invitation_confirmation_keys') IS NULL
  THEN
    RAISE EXCEPTION 'Required Production invitation key preservation/recovery table missing';
  END IF;
  IF to_regprocedure('public.handle_new_user_profile()') IS NULL THEN
    RAISE EXCEPTION 'Auth signup profile function missing';
  END IF;
  IF to_regprocedure('public.rls_auto_enable()') IS NULL THEN
    RAISE EXCEPTION 'RLS event trigger function missing';
  END IF;
END $$;

INSERT INTO private.company_invitation_confirmation_keys (singleton, key_hash)
SELECT singleton, key_hash
FROM pg_temp.horus345_prod_invitation_key
ON CONFLICT (singleton) DO UPDATE SET key_hash = EXCLUDED.key_hash;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM private.company_invitation_confirmation_keys live
    JOIN pg_temp.horus345_prod_invitation_key saved USING (singleton)
    WHERE live.key_hash = saved.key_hash
      AND octet_length(live.key_hash) = 32
  ) THEN
    RAISE EXCEPTION 'Production invitation confirmation key mismatch';
  END IF;
END $$;

CREATE TRIGGER on_auth_user_created_create_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();

CREATE EVENT TRIGGER ensure_rls ON ddl_command_end
  WHEN TAG IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
  EXECUTE FUNCTION public.rls_auto_enable();
