-- H.O.R.U.S System — Issue #236 / PC-12
-- Cover the replacement-history foreign key while preserving one-replacement semantics.

BEGIN;

DROP INDEX IF EXISTS public.fleet_license_documents_replaces_once_idx;

CREATE UNIQUE INDEX fleet_license_documents_replaces_once_idx
  ON public.fleet_license_documents(replaces_document_id);

COMMIT;
