#!/usr/bin/env python3
"""Issue #314 two-connection concurrency probe for an isolated Development database.

Requires psycopg >=3 (install in an isolated environment). Never use Production.
Set HORUS_DEV_DATABASE_URL securely; the URL and invitation hashes are not logged.
The probe creates one disposable invitation and revokes it afterward via the
audited RPC. It leaves audit evidence, but no usable invitation.
"""
import os
import secrets
import sys
import threading
import time
import uuid

try:
    import psycopg
except ImportError:
    sys.exit("Install psycopg in an isolated test environment: python -m pip install 'psycopg[binary]>=3,<4'")

DEV_REF = "zwnfmszssxtfxkaofnhq"
dsn = os.environ.get("HORUS_DEV_DATABASE_URL", "")
if not dsn:
    sys.exit("Missing HORUS_DEV_DATABASE_URL (Development only).")
try:
    parsed = psycopg.conninfo.conninfo_to_dict(dsn)
except Exception:
    sys.exit("Invalid Development connection string.")
host = parsed.get("host", "")
if DEV_REF not in host and os.environ.get("HORUS_DEV_DB_HOST_VERIFIED") != DEV_REF:
    sys.exit("Database host cannot be verified as H.O.R.U.S Development. Refusing to connect.")

def owner_scope(conn, user_id):
    conn.execute("SELECT set_config('request.jwt.claim.sub', %s, true)", (str(user_id),))
    conn.execute("SELECT set_config('request.jwt.claim.role', 'authenticated', true)")

with psycopg.connect(dsn, autocommit=False) as setup:
    company_id, owner_id = setup.execute("""
        SELECT member.company_id, member.user_id
        FROM public.company_users member
        JOIN public.companies company
          ON company.id = member.company_id AND company.is_active
        WHERE member.role = 'owner' AND member.is_active
        ORDER BY member.company_id LIMIT 1
    """).fetchone()
    owner_scope(setup, owner_id)
    token_hash = secrets.token_bytes(32)
    invitation_id = setup.execute("""
        SELECT invitation_id
        FROM public.prepare_company_invitation(
          %s::uuid, %s::text, 'viewer'::public.company_role, %s::bytea
        )
    """, (company_id, f"issue314-concurrent-{uuid.uuid4().hex}@example.invalid", token_hash)).fetchone()[0]
    setup.commit()

results = {}
barrier = threading.Barrier(2)
errors = []

def attempt(label, hold_lock):
    try:
        with psycopg.connect(dsn, autocommit=False) as conn:
            owner_scope(conn, owner_id)
            # Independent PostgreSQL backend connections and transactions.
            barrier.wait(timeout=10)
            if not hold_lock:
                time.sleep(0.2)
            try:
                row = conn.execute("""
                    SELECT delivery_attempt_id
                    FROM public.prepare_company_invitation_resend(
                      %s::uuid, %s::uuid, %s::bytea
                    )
                """, (company_id, invitation_id, secrets.token_bytes(32))).fetchone()
                results[label] = "prepared" if row else "unexpected_empty"
                if hold_lock:
                    time.sleep(2)
                conn.commit()
            except psycopg.Error as ex:
                conn.rollback()
                results[label] = ex.sqlstate or "unclassified_db_error"
    except Exception as ex:
        errors.append(f"{label}: {type(ex).__name__}")

workers = [threading.Thread(target=attempt, args=("first", True)),
           threading.Thread(target=attempt, args=("second", False))]
try:
    for worker in workers:
        worker.start()
    for worker in workers:
        worker.join(timeout=30)
    if any(worker.is_alive() for worker in workers):
        errors.append("Concurrent database call timed out")
    with psycopg.connect(dsn) as verify:
        old_hash, pending_attempt, prepared_events = verify.execute("""
            SELECT invitation.token_hash, invitation.pending_delivery_attempt_id,
                   (SELECT count(*) FROM public.audit_logs audit
                    WHERE audit.entity_id = invitation.id::text
                      AND audit.metadata->>'audit_event' =
                          'company_invitation_resend_prepared')
            FROM public.company_invitations invitation WHERE invitation.id = %s
        """, (invitation_id,)).fetchone()
    success = (not errors and sorted(results.values()) == ["P2816", "prepared"]
               and old_hash == token_hash and pending_attempt is not None
               and prepared_events == 1)
    print("Issue #314 two-session resend:",
          "PASS" if success else "FAIL",
          "| outcomes:", sorted(results.values()),
          "| original preserved:", old_hash == token_hash,
          "| audit events:", prepared_events)
finally:
    with psycopg.connect(dsn, autocommit=False) as cleanup:
        owner_scope(cleanup, owner_id)
        cleanup.execute(
            "SELECT * FROM public.revoke_company_invitation(%s::uuid, %s::uuid)",
            (company_id, invitation_id),
        )
        cleanup.commit()
        print("Fixture revoked via audited RPC.")
if not success:
    sys.exit(1)
