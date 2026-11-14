"""Issue #357: verify the private uploader FK index on disposable local DB.

Reads only catalog metadata after all repository migrations are replayed.
Never connects to hosted Supabase or exposes user data.
"""

from verify_issue_365_local_http import check, local_stack, psql


def main():
    _, _, _, db = local_stack()

    check("reservation uploader FK retains ON DELETE SET NULL",
          psql(db, "SELECT count(*) FROM pg_constraint "
                   "WHERE conrelid='private.business_document_upload_reservations'::regclass "
                   "AND conname='business_document_upload_reservations_actor_user_id_fkey' "
                   "AND contype='f' AND confrelid='auth.users'::regclass "
                   "AND confdeltype='n';") == "1")

    check("new valid full B-tree index covers actor_user_id as leading key",
          psql(db, "SELECT count(*) FROM pg_index i "
                   "JOIN pg_class idx ON idx.oid=i.indexrelid "
                   "JOIN pg_am am ON am.oid=idx.relam "
                   "JOIN pg_attribute a ON a.attrelid=i.indrelid "
                   "WHERE i.indrelid='private.business_document_upload_reservations'::regclass "
                   "AND idx.relname='business_document_reservation_actor_user_id_idx' "
                   "AND am.amname='btree' AND i.indisvalid AND i.indisready "
                   "AND i.indpred IS NULL AND i.indnkeyatts=1 "
                   "AND i.indkey[0]=a.attnum AND a.attname='actor_user_id';") == "1")

    check("reservation ledger remains RLS protected and not client-readable",
          psql(db, "SELECT relrowsecurity AND NOT "
                   "has_table_privilege('authenticated',oid,'SELECT') "
                   "AND NOT has_table_privilege('anon',oid,'SELECT') "
                   "FROM pg_class WHERE oid="
                   "'private.business_document_upload_reservations'::regclass;") == "t")

    print("PASS Issue #357 uploader FK index and privacy regression", flush=True)


if __name__ == "__main__":
    main()
