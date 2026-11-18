"""#351 branding orphan cleanup: disposable signed-JWT + Storage API acceptance.

This script uses ONLY the local Supabase CLI stack. No hosted project keys,
test company data or Production services are touched or imported.
"""
import concurrent.futures
import json
import secrets
import urllib.error
import urllib.request
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc
from verify_issue_351_branding import (
    PNG, denied, logo_key, onboard, row, storage
)


def service(api, method, payload):
    return api.call("POST", "/rest/v1/rpc/" + method,
                    admin=True, payload=payload)


def created_logo(api, jwt, company):
    path = logo_key(company)
    op = str(uuid.uuid4())
    status, _ = rpc(api, jwt, "reserve_company_branding_upload", {
        "p_company_id": company,
        "p_operation_id": op,
        "p_storage_path": path,
    })
    check("authorized manager reserves immutable branding object",
          status in (200, 204))
    check("authorized manager uploads private branding bytes",
          storage(api, jwt, "POST", path, PNG) in (200, 201))
    return path, op


def select_logo(api, jwt, company, expected, path):
    return row(rpc(api, jwt, "set_company_brand_logo", {
        "p_company_id": company,
        "p_expected_logo_path": expected,
        "p_new_logo_path": path,
    }), "valid tenant logo transition")


def remove_bytes(api, path):
    """Use the actual service-role Storage API; never DELETE storage.objects."""
    endpoint = api.url + "/storage/v1/object/company-branding"
    request = urllib.request.Request(
        endpoint,
        method="DELETE",
        headers={
            "apikey": api.admin,
            "Authorization": "Bearer " + api.admin,
            "Content-Type": "application/json",
        },
        data=json.dumps({"prefixes": [path]}).encode(),
    )
    try:
        with urllib.request.urlopen(request, timeout=25) as response:
            return response.status
    except urllib.error.HTTPError as failure:
        failure.read()
        return failure.code


def count(db, company, expression):
    return int(psql(
        db, "SELECT count(*) FROM private.company_branding_uploads"
            " WHERE company_id='" + company + "' AND " + expression + ";"
    ))


def mark_old(db, company, a, b, orphan):
    # Only a disposable local database can adjust timestamps for acceptance
    # without waiting for the scheduled, production-safe grace period.
    psql(db,
         "UPDATE private.company_branding_uploads "
         "SET retired_at=pg_catalog.now()-interval '1 day' "
         "WHERE company_id='" + company + "' "
         "AND storage_path IN ('" + a + "','" + b + "');")
    psql(db,
         "UPDATE private.company_branding_uploads "
         "SET reserved_at=pg_catalog.now()-interval '2 days', "
         "expires_at=pg_catalog.now()-interval '1 day' "
         "WHERE company_id='" + company + "' "
         "AND storage_path='" + orphan + "';")


def claim(api, batch_limit=25):
    status, rows = service(api, "claim_company_branding_cleanup",
                           {"p_batch_limit": batch_limit})
    check("service role claims bounded private cleanup leases",
          status == 200 and isinstance(rows, list))
    return rows


def preflight(api, company, operation):
    status, safe = service(api, "verify_company_branding_cleanup_lease", {
        "p_company_id": company,
        "p_operation_id": operation,
    })
    check("server verifies pending and unreferenced cleanup lease",
          status == 200 and safe is True)


def complete(api, company, operation):
    status, _ = service(api, "complete_company_branding_cleanup", {
        "p_company_id": company,
        "p_operation_id": operation,
    })
    check("service role finalizes deleted branding object", status in (200, 204))


def main():
    url, publishable, admin_key, db = local_stack()
    api = LocalApi(url, publishable, admin_key)
    nonce = secrets.token_hex(6)
    owner_id, owner_jwt = api.create_session("cleanup-owner", nonce)
    viewer_id, viewer_jwt = api.create_session("cleanup-viewer", nonce)
    _, foreign_jwt = api.create_session("cleanup-foreign", nonce)
    company = onboard(api, owner_jwt, nonce)
    foreign_company = onboard(api, foreign_jwt, nonce + "-other")
    psql(db, "INSERT INTO public.company_users "
         "(company_id,user_id,role,is_active,created_by) VALUES ('"
         + company + "','" + viewer_id + "','viewer',true,'"
         + owner_id + "');")

    check("no hosted cron job recreated in disposable migration replay",
          psql(db, "SELECT count(*) FROM cron.job WHERE jobname="
               "'horus-business-document-cleanup';") == "0")
    check("application roles cannot execute cleanup RPCs",
          psql(db, "SELECT has_function_privilege('authenticated',"
               "'public.claim_company_branding_cleanup(integer)',"
               "'EXECUTE')::text;") == "false")
    check("anonymous clients cannot execute cleanup RPCs",
          psql(db, "SELECT has_function_privilege('anon',"
               "'public.complete_company_branding_cleanup(uuid,uuid)',"
               "'EXECUTE')::text;") == "false")
    for token, who in ((owner_jwt, "owner"), (viewer_jwt, "viewer"),
                       (foreign_jwt, "foreign tenant"), (None, "anonymous")):
        status, _ = rpc(api, token, "claim_company_branding_cleanup",
                        {"p_batch_limit": 25})
        check(who + " cannot invoke service-role cleanup", status >= 400)

    a, aop = created_logo(api, owner_jwt, company)
    select_logo(api, owner_jwt, company, None, a)

    customer = psql(
        db, "INSERT INTO public.customers(company_id,name) VALUES ('"
        + company + "','CLEANUP-ISSUER-TEST') RETURNING id;"
    )
    invoice = psql(db,
        "INSERT INTO public.invoices "
        "(company_id,customer_id,currency_code,customer_name,"
        "subtotal_minor_units,taxable_minor_units,tax_minor_units,"
        "total_minor_units) VALUES ('" + company + "','" + customer
        + "','AED','CLEANUP-ISSUER-TEST',100,100,0,100) RETURNING id;"
    )
    # Minimal issuer-trigger fixture, not a hosted invoice or a new billing
    # workflow. Actual issue_invoice RPC is verified in the #351 parent test.
    psql(db,
        "UPDATE public.invoices SET status='issued',"
        "invoice_number='HORUS351-2026-777777',"
        "issue_date=CURRENT_DATE,due_date=CURRENT_DATE,"
        "issued_at=now(),issued_by='" + owner_id + "' WHERE id='"
        + invoice + "';")
    check("issued invoice captures original active logo",
          psql(db, "SELECT issuer_logo_path FROM public.invoices WHERE id='"
               + invoice + "';") == a)

    b, bop = created_logo(api, owner_jwt, company)
    select_logo(api, owner_jwt, company, a, b)
    active, active_op = created_logo(api, owner_jwt, company)
    select_logo(api, owner_jwt, company, b, active)
    orphan, orphan_op = created_logo(api, owner_jwt, company)
    check("retired assets receive a DB-owned retirement timestamp",
          count(db, company, "state='retired' AND retired_at IS NOT NULL") == 2)
    mark_old(db, company, a, b, orphan)

    check("retired, referenced invoice logo cannot be claimed",
          psql(db, "SELECT private.company_branding_logo_is_referenced('"
               + a + "')::text;") == "true")
    check("existing #357 Cron due-work predicate includes branding backlog",
          psql(db, "SELECT private.business_document_cleanup_has_work()"
               "::text;") == "true")
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        batches = list(pool.map(lambda _: claim(api, batch_limit=1), range(2)))
    leases = [lease for batch in batches for lease in batch]
    check("parallel cleanup claims do not double-claim a lease",
          len(leases) == 2 and
          len({lease["operation_id"] for lease in leases}) == 2)
    selected = {r["storage_reference"]: r for r in leases}
    check("only expired orphan and unreferenced retired logo claimed",
          set(selected) == {b, orphan} and len(leases) == 2)
    check("active logo not claimed", active not in selected)
    check("invoice-linked retired logo not claimed", a not in selected)

    def denied_completion(path):
        lease = selected[path]
        denied(service(api, "complete_company_branding_cleanup", {
            "p_company_id": company,
            "p_operation_id": lease["operation_id"],
        }), "P3514", "cannot finalize while Storage bytes remain")

    denied_completion(b)
    for path in (b, orphan):
        preflight(api, company, selected[path]["operation_id"])

    # Simulate a transient Storage outage: retry must not lose the lease or
    # modify active branding, and the next claim waits for its lease TTL.
    status, _ = service(api, "defer_company_branding_cleanup", {
        "p_company_id": company,
        "p_operation_id": bop,
        "p_error_code": "storage_remove_failed",
    })
    check("failed Storage deletion recorded with stable failure code",
          status in (200, 204))
    check("deferred lease remains retryable and not incorrectly cleaned",
          count(db, company, "operation_id='" + bop + "' AND "
                "state='cleanup_pending' AND "
                "last_cleanup_error_code='storage_remove_failed' "
                "AND cleanup_attempts=1") == 1)
    check("deferred lease is not immediately reclaimed", claim(api) == [])

    psql(db,
        "UPDATE private.company_branding_uploads "
        "SET cleanup_claimed_at=pg_catalog.now()-interval '1 hour' "
        "WHERE company_id='" + company + "' AND operation_id='"
        + bop + "';")
    again = claim(api)
    check("stale cleanup lease is reclaimed once after timeout",
          len(again) == 1 and again[0]["storage_reference"] == b)
    check("persistent retry attempts increment without losing tenant",
          count(db, company, "operation_id='" + bop + "' AND "
                "cleanup_attempts=2 AND last_cleanup_error_code IS NULL") == 1)

    # Complete via real Storage REST DELETE, not SQL metadata deletion.
    for path, op in ((b, bop), (orphan, orphan_op)):
        preflight(api, company, op)
        check("service-role Storage API removes unreferenced bytes",
              remove_bytes(api, path) == 200)
        complete(api, company, op)
        check("cleanup is durable with completed timestamp",
              count(db, company, "operation_id='" + op
                    + "' AND state='cleaned' AND cleaned_at IS NOT NULL") == 1)
        check("cleaned object no longer exists in Storage metadata",
              psql(db, "SELECT count(*) FROM storage.objects WHERE "
                   "bucket_id='company-branding' AND name='" + path
                   + "';") == "0")

    check("active and historical invoice Storage bytes are preserved",
          psql(db,
               "SELECT count(*) FROM storage.objects WHERE "
               "bucket_id='company-branding' AND name IN ('"
               + a + "','" + active + "');") == "2")
    check("issuer logo snapshot remains unchanged after cleanup",
          psql(db, "SELECT issuer_logo_path FROM public.invoices WHERE id='"
               + invoice + "';") == a)
    check("already cleaned assets never appear in another claim",
          claim(api) == [])
    check("work-gated #357 Cron skips an idle branding lifecycle",
          psql(db, "SELECT private.business_document_cleanup_has_work()"
               "::text;") == "false")
    check("branding storage does not consume business document quotas",
          psql(db, "SELECT private.company_quota_used('"
               + company + "','business_documents')::text;") == "0")
    check("second tenant is untouched by original company's cleanup",
          psql(db, "SELECT count(*) FROM private.company_branding_uploads "
               "WHERE company_id='" + foreign_company + "';") == "0")

    print("PASS #351 branding cleanup lease, service role, grace, RLS, "
          "Storage delete, invoice history, retries and #357 Cron gate",
          flush=True)


if __name__ == "__main__":
    main()
