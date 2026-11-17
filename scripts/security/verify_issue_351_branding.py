"""Issue #351: disposable signed-JWT branding and issuer-identity contract.

Runs ONLY against a locally booted Supabase CLI instance. No hosted keys.
The full invoice-issue RPC needs a separate integration fixture; this script
proves the database issuer trigger, row immutability and private Storage RLS.
"""
from datetime import datetime, timezone
import base64
import secrets
import urllib.error
import urllib.parse
import urllib.request
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc, uid


# Minimal valid 1x1 PNG, no user files, secrets or external fixtures.
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9SUFfEsAAAAASUVORK5CYII="
)


def row(result, label):
    status, body = result
    records = body if isinstance(body, list) else [body]
    check(label, status == 200 and len(records) == 1
          and isinstance(records[0], dict))
    return records[0]


def denied(result, code, label):
    status, body = result
    check(label, status >= 400 and isinstance(body, dict)
          and body.get("code") == code)


def onboard(api, jwt, nonce):
    result = rpc(api, jwt, "create_company_with_initial_owner", {
        "p_name": "HORUS351-" + nonce,
        "p_request_id": str(uuid.uuid4()),
        "p_business_timezone": "UTC",
        "p_base_currency_code": "AED",
        "p_base_currency_fraction_digits": 2,
        "p_invoice_prefix": "HORUS351",
    })
    return uid(row(result, "signed owner JWT onboards Free Starter tenant")["id"])


def profile(api, jwt, company):
    return row(api.call(
        "GET", "/rest/v1/companies", token=jwt,
        query={"id": "eq." + company,
               "select": "id,name,updated_at,logo_url,address,tax_registration_number"}
    ), "tenant profile is readable to its member")


def change_profile(api, jwt, company, expected, name):
    return rpc(api, jwt, "update_company_brand_profile", {
        "p_company_id": company,
        "p_expected_updated_at": expected,
        "p_name": name,
        "p_business_type": "Heavy Transport",
        "p_phone": "+971000000000",
        "p_email": "test@example.test",
        "p_country": "UAE",
        "p_city": "Dubai",
        "p_address": "Disposable local test address",
        "p_tax_registration_number": None,
    })


def logo_key(company):
    return "companies/" + company + "/logos/" + str(uuid.uuid4()) + ".png"


def storage(api, jwt, method, path, data=None):
    url = (api.url + "/storage/v1/object/company-branding/"
           + urllib.parse.quote(path, safe="/"))
    headers = {
        "apikey": api.public,
        "Authorization": "Bearer " + jwt if jwt else "Bearer " + api.public,
        "Content-Type": "image/png",
        "x-upsert": "false",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=25) as response:
            return response.status
    except urllib.error.HTTPError as error:
        error.read()
        return error.code


def count(db, table, predicate):
    return int(psql(db, "SELECT count(*) FROM " + table
                    + " WHERE " + predicate + ";"))


def main():
    url, publishable, admin_key, db = local_stack()
    api = LocalApi(url, publishable, admin_key)
    nonce = secrets.token_hex(6)
    accounts = {
        role: api.create_session("branding-" + role, nonce)
        for role in ("owner", "admin", "viewer", "foreign")
    }
    owner_id, owner_jwt = accounts["owner"]
    company = onboard(api, owner_jwt, nonce)
    foreign_company = onboard(api, accounts["foreign"][1], nonce + "-other")

    for role in ("admin", "viewer"):
        user_id = accounts[role][0]
        psql(db, "INSERT INTO public.company_users "
             "(company_id,user_id,role,is_active,created_by) VALUES ('"
             + company + "','" + user_id + "','" + role + "',true,'"
             + owner_id + "');")

    # Read access is tenant-scoped, including Viewer and Admin membership.
    for role in ("viewer", "admin"):
        status, rows = api.call(
            "GET", "/rest/v1/companies", token=accounts[role][1],
            query={"id": "eq." + company, "select": "id,name"}
        )
        check(role + " reads own tenant company identity",
              status == 200 and isinstance(rows, list)
              and len(rows) == 1 and rows[0]["id"] == company)
    status, foreign_rows = api.call(
        "GET", "/rest/v1/companies", token=accounts["foreign"][1],
        query={"id": "eq." + company, "select": "id"}
    )
    check("foreign tenant cannot read this company's brand identity",
          status == 200 and foreign_rows == [])

    initial = profile(api, owner_jwt, company)
    original_name = initial["name"]
    before_audit = count(db, "public.audit_logs",
                         "company_id='" + company
                         + "' AND metadata->>'audit_event'="
                           "'company_brand_profile_updated'")
    edited_name = original_name + "-EDITED"
    updated = row(change_profile(
        api, owner_jwt, company, initial["updated_at"], edited_name
    ), "owner updates supported business identity")
    check("address saved, tax field optional, unrelated finance retained",
          updated["address"] == "Disposable local test address"
          and updated["tax_registration_number"] is None
          and updated["base_currency_code"] == "AED")
    check("one structured profile audit event",
          count(db, "public.audit_logs",
                "company_id='" + company
                + "' AND metadata->>'audit_event'="
                  "'company_brand_profile_updated'") == before_audit + 1)
    denied(change_profile(
        api, owner_jwt, company, initial["updated_at"], "stale"
    ), "P3512", "stale profile update denied")
    for role in ("viewer", "foreign"):
        denied(change_profile(
            api, accounts[role][1], company,
            updated["updated_at"], "unauthorized"
        ), "P3510", role + " cannot change business identity")
    anon_status, _ = change_profile(
        api, None, company, updated["updated_at"], "anonymous"
    )
    check("anonymous cannot invoke privileged profile RPC",
          anon_status in (401, 403, 404))

    status, body = api.call(
        "PATCH", "/rest/v1/companies", token=owner_jwt,
        query={"id": "eq." + company},
        payload={"name": "DIRECT-BYPASS"}
    )
    check("direct company UPDATE remains inaccessible",
          status in (401, 403) and isinstance(body, dict))
    check("denied mutations produced no extra audit",
          count(db, "public.audit_logs",
                "company_id='" + company
                + "' AND metadata->>'audit_event'="
                  "'company_brand_profile_updated'") == before_audit + 1)

    admin_updated = row(change_profile(
        api, accounts["admin"][1], company,
        updated["updated_at"], edited_name + "-ADMIN"
    ), "authorized Admin can edit tenant business identity")
    check("Admin profile change stays company scoped",
          admin_updated["id"] == company
          and admin_updated["name"] == edited_name + "-ADMIN")
    restored = row(change_profile(
        api, owner_jwt, company, admin_updated["updated_at"], edited_name
    ), "owner restores company identity after Admin edit")
    check("Admin mutation and owner restoration both audited",
          restored["name"] == edited_name
          and count(db, "public.audit_logs",
                    "company_id='" + company
                    + "' AND metadata->>'audit_event'="
                      "'company_brand_profile_updated'") == before_audit + 3)

    path = logo_key(company)
    reserve = lambda jwt, company_id, op, key: rpc(
        api, jwt, "reserve_company_branding_upload", {
            "p_company_id": company_id,
            "p_operation_id": op,
            "p_storage_path": key,
        }
    )
    check("unreserved owner upload rejected",
          storage(api, owner_jwt, "POST", path, PNG) >= 400)
    operation = str(uuid.uuid4())
    for role in ("viewer", "foreign"):
        denied(reserve(accounts[role][1], company, operation, path),
               "P3510", role + " cannot reserve tenant logo")
    denied(reserve(owner_jwt, company, operation, logo_key(foreign_company)),
           "P3511", "owner cannot reserve foreign path")
    status, _ = reserve(owner_jwt, company, operation, path)
    check("owner reserves quota-exempt logo", status in (200, 204))
    status, _ = reserve(owner_jwt, company, operation, path)
    check("identical live upload reservation retry is idempotent",
          status in (200, 204))
    check("viewer cannot upload against owner's reservation",
          storage(api, accounts["viewer"][1], "POST", path, PNG) >= 400)
    check("owner uploads private logo after reservation",
          storage(api, owner_jwt, "POST", path, PNG) in (200, 201))
    check("logo cannot be overwritten",
          storage(api, owner_jwt, "POST", path, PNG) >= 400)
    check("branding upload did not consume a document quota slot",
          psql(db, "SELECT private.company_quota_used('"
               + company + "','business_documents')::text;") == "0")

    switched = row(rpc(api, owner_jwt, "set_company_brand_logo", {
        "p_company_id": company,
        "p_expected_logo_path": None,
        "p_new_logo_path": path,
    }), "owner selects uploaded logo")
    check("company stores only private canonical key",
          switched["logo_url"] == path)
    denied(rpc(api, accounts["viewer"][1], "set_company_brand_logo", {
        "p_company_id": company, "p_expected_logo_path": path,
        "p_new_logo_path": None
    }), "P3510", "viewer cannot remove logo")
    denied(rpc(api, accounts["foreign"][1], "set_company_brand_logo", {
        "p_company_id": company, "p_expected_logo_path": path,
        "p_new_logo_path": None
    }), "P3510", "foreign company cannot remove logo")

    # Build a minimal disposable invoice fixture; the issued identity trigger
    # runs in the same transaction as an authoritative issue_invoice RPC.
    customer = uid(psql(db,
        "INSERT INTO public.customers(company_id,name) VALUES ('"
        + company + "','ISSUER SNAPSHOT TEST') RETURNING id;"))
    invoice = uid(psql(db,
        "INSERT INTO public.invoices "
        "(company_id,customer_id,currency_code,customer_name,"
        "subtotal_minor_units,taxable_minor_units,tax_minor_units,"
        "total_minor_units) VALUES ('" + company + "','" + customer
        + "','AED','ISSUER SNAPSHOT TEST',100,100,0,100) RETURNING id;"))
    psql(db,
        "UPDATE public.invoices SET status='issued',"
        "invoice_number='HORUS351-2026-000999',"
        "issue_date=CURRENT_DATE,due_date=CURRENT_DATE,"
        "issued_at=now(),issued_by='" + owner_id + "' WHERE id='" + invoice + "';")
    check("issuer name and immutable logo captured at issuance",
          psql(db, "SELECT issuer_company_name || '|' || issuer_logo_path"
               " || '|' || issuer_snapshot_source FROM public.invoices "
               "WHERE id='" + invoice + "';")
          == edited_name + "|" + path + "|issuance")

    # Exercise the genuine signed-JWT Invoice issue RPC, not only a
    # privileged SQL fixture that triggers the same database hook.
    route = uid(psql(
        db, "INSERT INTO public.routes"
            "(company_id,loading_location,unloading_location) VALUES ('"
            + company + "','ISSUE351-START','ISSUE351-END') RETURNING id;"
    ))
    trip = row(rpc(api, owner_jwt, "create_trip_idempotent", {
        "p_request_id": str(uuid.uuid4()),
        "p_company_id": company,
        "p_customer_id": customer,
        "p_route_id": route,
    }), "signed owner creates a billable trip")["id"]
    # Set operational evidence on the disposable local fixture only.
    psql(db, "BEGIN; SET LOCAL session_replication_role=replica; "
         "UPDATE public.trips SET status='documents_received',"
         "freight_price=100,quantity_tons=1 "
         "WHERE company_id='" + company + "' AND id='" + trip + "'; COMMIT;")
    status, live_draft = rpc(api, owner_jwt,
                             "create_invoice_draft_idempotent", {
        "p_request_id": str(uuid.uuid4()),
        "p_company_id": company,
        "p_customer_id": customer,
        "p_trip_ids": [trip],
        "p_discount_minor_units": 0,
        "p_tax_rate_basis_points": 0,
        "p_issue_date": None,
        "p_due_date": None,
        "p_notes": "local-only issuer snapshot acceptance",
    })
    check("signed owner creates valid invoice draft",
          status == 200 and isinstance(live_draft, str))
    today = datetime.now(timezone.utc).date().isoformat()
    status, live_issued = rpc(api, owner_jwt, "issue_invoice", {
        "p_company_id": company,
        "p_invoice_id": live_draft,
        "p_issue_date": today,
        "p_due_date": today,
    })
    if status != 200 or live_issued != live_draft:
        # Safe diagnostic: no client tokens, user identifiers or raw payloads.
        error_code = (live_issued.get("code")
                      if isinstance(live_issued, dict) else None)
        print("ISSUE351_LIVE_INVOICE_ISSUE_DIAGNOSTIC",
              "http", status, "sqlstate", error_code, flush=True)
    check("signed owner issues invoice through actual RPC",
          status == 200 and live_issued == live_draft)
    check("real invoice issuance captures correct issuer name and logo",
          psql(db, "SELECT issuer_company_name || '|' || issuer_logo_path "
                  "|| '|' || issuer_snapshot_source FROM public.invoices "
                  "WHERE id='" + live_draft + "';")
          == edited_name + "|" + path + "|issuance")

    newest = profile(api, owner_jwt, company)
    row(change_profile(
        api, owner_jwt, company, newest["updated_at"], edited_name + "-NEW"
    ), "company identity can change after prior invoice issued")
    check("old invoice identity remains frozen after current name change",
          psql(db, "SELECT issuer_company_name FROM public.invoices "
               "WHERE id='" + invoice + "';") == edited_name)

    check("real issued invoice remains immutable after a profile edit",
          psql(db, "SELECT issuer_company_name || '|' || issuer_logo_path "
                  "FROM public.invoices WHERE id='" + live_draft + "';")
          == edited_name + "|" + path)

    # A protected Storage delete must refuse even after the CURRENT logo
    # is removed: the old invoice continues to reference that version.
    row(rpc(api, owner_jwt, "set_company_brand_logo", {
        "p_company_id": company, "p_expected_logo_path": path,
        "p_new_logo_path": None
    }), "owner removes current logo without deleting invoice history")
    referenced = psql(
        db, "SELECT private.company_branding_logo_is_referenced('"
            + path + "')::text;"
    )
    delete_status = storage(api, owner_jwt, "DELETE", path)
    retained_objects = count(
        db, "storage.objects",
        "bucket_id='company-branding' AND name='" + path + "'"
    )
    print("Referenced logo delete probe: HTTP", delete_status,
          "reference", referenced, "remaining", retained_objects,
          flush=True)
    check("invoice-referenced old logo bytes/metadata remain protected",
          referenced == "true" and retained_objects == 1)
    check("old invoice still has captured logo version",
          psql(db, "SELECT issuer_logo_path FROM public.invoices WHERE id='"
               + invoice + "';") == path)

    # Admin can independently reserve, upload and select its own logo
    # without using the Owner's reservation, and can remove it later.
    admin_path = logo_key(company)
    admin_operation = str(uuid.uuid4())
    admin_jwt = accounts["admin"][1]
    admin_status, _ = reserve(admin_jwt, company,
                              admin_operation, admin_path)
    check("Admin can reserve tenant branding upload",
          admin_status in (200, 204))
    check("Admin can upload its reserved private logo",
          storage(api, admin_jwt, "POST", admin_path, PNG) in (200, 201))
    admin_selected = row(rpc(api, admin_jwt, "set_company_brand_logo", {
        "p_company_id": company,
        "p_expected_logo_path": None,
        "p_new_logo_path": admin_path,
    }), "authorized Admin selects private company logo")
    check("Admin logo selection scoped to the correct company",
          admin_selected["logo_url"] == admin_path)
    admin_removed = row(rpc(api, admin_jwt, "set_company_brand_logo", {
        "p_company_id": company,
        "p_expected_logo_path": admin_path,
        "p_new_logo_path": None,
    }), "authorized Admin removes private company logo")
    check("Admin can remove current logo while issued history remains frozen",
          admin_removed["logo_url"] is None
          and psql(db, "SELECT issuer_logo_path FROM public.invoices "
                   "WHERE id='" + live_draft + "';") == path)

    print("Issue #351 disposable signed-JWT branding contract: PASS",
          flush=True)


if __name__ == "__main__":
    main()
