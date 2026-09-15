-- H.O.R.U.S System — Issue #227 / PC-03
-- The reusable foundation supports upload/download/delete only.
-- Keep UPDATE denied by default; feature-specific update semantics must opt in later.

BEGIN;

DROP POLICY IF EXISTS business_documents_update_managers ON storage.objects;

COMMIT;
