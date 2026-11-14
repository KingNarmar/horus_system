-- H.O.R.U.S #357: cover the uploader Auth FK in the private reservation ledger.
-- A full B-tree index supports auth.users delete / ON DELETE SET NULL.
-- No quotas, RLS policies, grants, business logic or existing data change.
-- Previously applied migrations must remain immutable.
BEGIN;

CREATE INDEX business_document_reservation_actor_user_id_idx
  ON private.business_document_upload_reservations USING btree (actor_user_id);

COMMIT;
