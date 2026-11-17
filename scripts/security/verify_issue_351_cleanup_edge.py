"""#351 Edge runtime smoke: reuse the existing local Vault-authenticated worker.

Runs against ONLY a disposable local Supabase CLI stack with 'functions serve'
started by the CI workflow. Never uses hosted tokens, URLs or operator data.
"""
import json
import secrets
import time
import urllib.error
import urllib.request
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc
from verify_issue_351_branding import logo_key, onboard, row, storage, PNG


def invoke(endpoint, token):
    request = urllib.request.Request(
        endpoint,
        data=b"{}",
        method="POST",
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, json.loads(response.read().decode())
    except urllib.error.HTTPError as failure:
        failure.read()
        return failure.code, None


def main():
    url, publishable, admin_key, db = local_stack()
    api = LocalApi(url, publishable, admin_key)
    nonce = secrets.token_hex(6)
    _, owner_jwt = api.create_session("edge-branding", nonce)
    company = onboard(api, owner_jwt, nonce)
    logo = logo_key(company)
    # This is a disposable UUID, not a user account or project secret.
    operation_id = str(uuid.uuid4())

    status, _ = rpc(api, owner_jwt, "reserve_company_branding_upload", {
        "p_company_id": company, "p_operation_id": operation_id,
        "p_storage_path": logo,
    })
    check("runtime fixture reserves branding asset", status in (200, 204))
    check("runtime fixture uploads private Storage bytes",
          storage(api, owner_jwt, "POST", logo, PNG) in (200, 201))
    row(rpc(api, owner_jwt, "set_company_brand_logo", {
        "p_company_id": company, "p_expected_logo_path": None,
        "p_new_logo_path": logo,
    }), "runtime fixture selects logo")
    row(rpc(api, owner_jwt, "set_company_brand_logo", {
        "p_company_id": company, "p_expected_logo_path": logo,
        "p_new_logo_path": None,
    }), "runtime fixture retires unreferenced logo")
    psql(db,
         "UPDATE private.company_branding_uploads SET retired_at="
         "pg_catalog.now()-interval '1 day' WHERE company_id='"
         + company + "' AND operation_id='" + operation_id + "';")

    token = psql(db,
        "SELECT decrypted_secret FROM vault.decrypted_secrets WHERE "
        "name='horus_business_document_cleanup_token';"
    )
    check("local Vault token is available to the scheduled worker",
          len(token) == 64)

    endpoint = url + "/functions/v1/business-document-cleanup"
    # Only poll readiness on the disposable Edge runtime; do not wait for any
    # hosted asynchronous process or claim that remote work has completed.
    ready = False
    for _ in range(40):
        try:
            status, _ = invoke(endpoint, "0" * 64)
            if status == 401:
                ready = True
                break
        except urllib.error.URLError:
            pass
        time.sleep(1)
    check("local Edge runtime started with invalid-token denial", ready)

    check("unauthorized Edge calls leave branding bytes untouched",
          psql(db, "SELECT count(*) FROM storage.objects WHERE bucket_id="
               "'company-branding' AND name='" + logo + "';") == "1")
    status, body = invoke(endpoint, token)
    check("Vault-authorized Edge runs original job and branding worker",
          status == 200 and body is not None
          and body.get("status") == "completed"
          and body.get("branding_inspected", 0) >= 1
          and body.get("branding_cleaned", 0) >= 1)
    check("Edge uses Storage.remove and finalizes branding lease",
          psql(db,
              "SELECT count(*) FROM private.company_branding_uploads "
              "WHERE company_id='" + company
              + "' AND state='cleaned' AND cleaned_at IS NOT NULL;") == "1"
          and psql(db,
              "SELECT count(*) FROM storage.objects WHERE "
              "bucket_id='company-branding' AND name='" + logo + "';") == "0")
    status, again = invoke(endpoint, token)
    check("idempotent second scheduled run does not re-delete assets",
          status == 200 and again.get("branding_inspected") == 0)
    check("Edge cleanup never consumes Starter document quota",
          psql(db, "SELECT private.company_quota_used('"
               + company + "','business_documents')::text;") == "0")
    print("PASS #351 live local Edge runtime, Vault authorization and "
          "Storage cleanup idempotency", flush=True)


if __name__ == "__main__":
    main()
