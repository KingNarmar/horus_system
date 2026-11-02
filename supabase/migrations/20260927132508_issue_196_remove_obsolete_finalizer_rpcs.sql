-- H.O.R.U.S System — Issue #196 finalizer surface cleanup
-- Automatic finalization is now an internal scheduled database operation.
-- Remove the earlier service-role RPC seam so there is only one finalization path.

BEGIN;

DROP FUNCTION IF EXISTS public.prepare_account_deletion_finalization(uuid);
DROP FUNCTION IF EXISTS public.complete_account_deletion_finalization(uuid);

COMMIT;
