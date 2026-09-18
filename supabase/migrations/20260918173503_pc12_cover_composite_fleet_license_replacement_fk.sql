-- H.O.R.U.S System — Issue #236 / PC-12
-- Cover the composite replacement-history foreign key exactly.

BEGIN;

DROP INDEX IF EXISTS public.fleet_license_documents_replaces_once_idx;

CREATE UNIQUE INDEX fleet_license_documents_replaces_once_idx
  ON public.fleet_license_documents(company_id, replaces_document_id);

COMMIT;
