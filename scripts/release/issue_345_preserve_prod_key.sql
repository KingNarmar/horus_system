-- #345: FIRST SQL file in ONE Production cutover psql session/transaction.
-- Never export the key_hash to Git, logs or the Development project.
-- A temp table deliberately disappears at transaction commit/rollback.
-- This is NOT intended for individual disconnected Supabase SQL tool calls.
CREATE TEMP TABLE horus345_prod_invitation_key ON COMMIT DROP AS
SELECT singleton, key_hash
FROM private.company_invitation_confirmation_keys
WHERE singleton IS TRUE;

DO $$
BEGIN
  IF (SELECT count(*) FROM pg_temp.horus345_prod_invitation_key) <> 1
     OR EXISTS (
       SELECT 1 FROM pg_temp.horus345_prod_invitation_key
       WHERE singleton IS NOT TRUE OR octet_length(key_hash) <> 32
     )
  THEN
    RAISE EXCEPTION 'Production invitation confirmation key preflight failed';
  END IF;
END $$;
