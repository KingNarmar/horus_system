-- H.O.R.U.S System — Issue #235 / PC-11
-- Cover Trip document foreign keys with focused indexes.

BEGIN;

DROP INDEX IF EXISTS public.trip_documents_replaces_once_idx;

CREATE UNIQUE INDEX trip_documents_replaces_once_idx
  ON public.trip_documents(company_id, replaces_document_id)
  WHERE replaces_document_id IS NOT NULL;

CREATE INDEX trip_documents_uploaded_by_idx
  ON public.trip_documents(uploaded_by)
  WHERE uploaded_by IS NOT NULL;

CREATE INDEX trip_documents_removed_by_idx
  ON public.trip_documents(removed_by)
  WHERE removed_by IS NOT NULL;

COMMIT;
