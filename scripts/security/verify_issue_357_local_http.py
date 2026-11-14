"""Issue #357: disposable-only signed JWT + Storage quota contract.

Requires a local Supabase CLI stack with repository migrations replayed.
Never accepts a hosted endpoint, prints JWTs or modifies user projects.
"""
import concurrent.futures
import json
import secrets
import urllib.error
import urllib.parse
import urllib.request
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc
from verify_issue_354_local_http import onboard, successful_company, denied
from verify_issue_356_local_http import fixture, creation, successful


DOCUMENT = b"%PDF-1.4\n%HORUS-357-LOCAL\n%%EOF\n"


def name(company, trip):
    return ("companies/" + company + "/trips/" + trip +
            "/waybill/" + secrets.token_hex(16) + ".pdf")


def reserve(api, jwt, company, path, operation=None, replacement=None):
    return rpc(api, jwt, "reserve_business_document_upload", {
        "p_company_id": company,
        "p_operation_id": operation or str(uuid.uuid4()),
        "p_bucket_id": "business-documents",
        "p_storage_reference": path,
        "p_replaces_reference": replacement,
    })


def release(api, jwt, company, path):
    return rpc(api, jwt, "release_business_document_upload_by_reference", {
        "p_company_id": company,
        "p_storage_reference": path,
    })


def usage(api, jwt, company):
    status, body = rpc(api, jwt, "get_company_quota_usage", {
        "p_company_id": company,
    })
    check("owner usage readable", status == 200 and isinstance(body, dict))
    return body["usage"]["business_documents"]


def storage(api, jwt, method, path, data=None):
    """Exercise the same Storage REST upload/download boundary as Flutter."""
    endpoint = ("/storage/v1/object/authenticated/" if method == "GET"
                else "/storage/v1/object/")
    url = api.url + endpoint + urllib.parse.quote(
        "business-documents/" + path, safe="/"
    )
    headers = {
        "apikey": api.public,
        "Authorization": "Bearer " + jwt if jwt else "",
    }
    if data is not None:
        headers["Content-Type"] = "application/pdf"
        headers["x-upsert"] = "false"
    request = urllib.request.Request(url, data=data, headers=headers,
                                     method=method)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as failure:
        return failure.code, failure.read()


def storage_remove(api, jwt, path, *, admin=False):
    """Use Storage API's batch DELETE endpoint, not an unsupported URL."""
    url = api.url + "/storage/v1/object/business-documents"
    headers = {
        "apikey": api.admin if admin else api.public,
        "Authorization": "Bearer " + jwt,
        "Content-Type": "application/json",
    }
    request = urllib.request.Request(
        url, data=json.dumps({"prefixes": [path]}).encode(),
        headers=headers, method="DELETE"
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, response.read()
    except urllib.error.HTTPError as failure:
        return failure.code, failure.read()


def assert_reserved(api, jwt, company, path):
    status, result = reserve(api, jwt, company, path)
    check("reservation acquired", status == 200
          and isinstance(result, dict) and result.get("state") == "reserved")


def active_reserved(db, company):
    return int(psql(
        db, "SELECT count(*) FROM private.business_document_upload_reservations "
        "WHERE company_id='" + company + "' AND state='reserved' "
        "AND expires_at>now();"
    ))


def main():
    url, public, admin, db = local_stack()
    api = LocalApi(url, public, admin)
    nonce = secrets.token_hex(6)

    # The local migration creates a secret WITHOUT leaking its value and
    # intentionally leaves Cron disabled when no environment URL is provided.
    check("one private cleanup token created in Vault",
          psql(db, "SELECT count(*) FROM vault.secrets "
                   "WHERE name='horus_business_document_cleanup_token';") == "1")
    check("only service_role may execute cleanup authorization RPC",
          psql(db, "SELECT "
                   "has_function_privilege('service_role', "
                   "'public.authorize_business_document_cleanup(text)', "
                   "'EXECUTE') AND NOT "
                   "has_function_privilege('authenticated', "
                   "'public.authorize_business_document_cleanup(text)', "
                   "'EXECUTE');") == "t")
    check("Vault-held token verifies without ever returning the secret",
          psql(db, "SELECT public.authorize_business_document_cleanup("
                   "(SELECT decrypted_secret FROM vault.decrypted_secrets "
                   "WHERE name='horus_business_document_cleanup_token'));") == "t")
    check("arbitrary cleanup tokens are rejected",
          psql(db, "SELECT NOT public.authorize_business_document_cleanup("
                   "repeat('0',64));") == "t")
    check("unconfigured local replay cannot schedule hosted cleanup",
          psql(db, "SELECT count(*) FROM cron.job "
                   "WHERE jobname='horus-business-document-cleanup';") == "0")

    check("idle cleanup has no HTTP work",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "f")
    check("tenants cannot read internal cleanup decision",
          psql(db, "SELECT NOT has_function_privilege('authenticated', "
                   "'private.business_document_cleanup_has_work()', "
                   "'EXECUTE');") == "t")

    owner_id, owner_jwt = api.create_session("owner", nonce)
    foreign_id, foreign_jwt = api.create_session("foreign", nonce)
    viewer_id, viewer_jwt = api.create_session("viewer", nonce)
    operations_id, operations_jwt = api.create_session("operations", nonce)

    company = successful_company(
        onboard(api, owner_jwt, str(uuid.uuid4()), "HORUS357-A-" + nonce),
        "first company onboarding",
    )
    other = successful_company(
        onboard(api, foreign_jwt, str(uuid.uuid4()), "HORUS357-B-" + nonce),
        "foreign company onboarding",
    )
    for role, account_id in (("viewer", viewer_id),
                             ("operations", operations_id)):
        psql(db, "INSERT INTO public.company_users"
             "(company_id,user_id,role,is_active,created_by) "
             "VALUES('" + company + "','" + account_id + "','" + role +
             "',true,'" + owner_id + "');")

    # Test both allowed Admin and denied Accountant roles in the other
    # company without exceeding its Free Starter three-member contract.
    admin_id, admin_jwt = api.create_session("admin", nonce)
    accountant_id, accountant_jwt = api.create_session("accountant", nonce)
    for role, user_id in (("admin", admin_id),
                          ("accountant", accountant_id)):
        psql(db, "INSERT INTO public.company_users "
             "(company_id,user_id,role,is_active,created_by) "
             "VALUES('" + other + "','" + user_id + "','" + role +
             "',true,'" + foreign_id + "');")
    b_customer, b_route = fixture(db, other, nonce + "-roles")
    b_trip = successful(
        creation(api, foreign_jwt, str(uuid.uuid4()),
                 other, b_customer, b_route),
        "role fixture Trip",
    )["id"]
    admin_path = name(other, b_trip)
    status, result = reserve(api, admin_jwt, other, admin_path)
    check("Admin can reserve within their company's document quota",
          status == 200 and result.get("state") == "reserved")
    status, _ = release(api, admin_jwt, other, admin_path)
    check("Admin cancellation releases reserved capacity",
          status in (200, 204))
    denied(reserve(api, accountant_jwt, other, name(other, b_trip)),
           "P2871", "Accountant cannot reserve operational documents")

    customer, route = fixture(db, company, nonce)
    trip = successful(
        creation(api, owner_jwt, str(uuid.uuid4()),
                 company, customer, route),
        "Trip quota fixture",
    )["id"]

    # Negative direct Data API mutations may not reassign a reserved Driver
    # licence image to a different Driver or an unrelated ID-image field.
    driver_a = psql(db, "INSERT INTO public.drivers(company_id,full_name) "
                    "VALUES('" + company + "','HORUS357-A') RETURNING id;")
    driver_b = psql(db, "INSERT INTO public.drivers(company_id,full_name) "
                    "VALUES('" + company + "','HORUS357-B') RETURNING id;")
    driver_path = ("companies/" + company + "/drivers/" + driver_a +
                   "/license-front/1790000000000000.png")
    status, leased = rpc(api, owner_jwt, "reserve_business_document_upload", {
        "p_company_id": company,
        "p_operation_id": str(uuid.uuid4()),
        "p_bucket_id": "driver-documents",
        "p_storage_reference": driver_path,
        "p_replaces_reference": None,
    })
    check("Driver identity upload reservation is tenant-scoped",
          status == 200 and leased.get("state") == "reserved")
    status, body = api.call(
        "PATCH", "/rest/v1/drivers", token=owner_jwt,
        query={"company_id": "eq." + company, "id": "eq." + driver_b,
               "select": "id"},
        payload={"license_image_path": driver_path},
    )
    check("Driver B cannot attach Driver A reserved licence image",
          status >= 400 and isinstance(body, dict)
          and body.get("code") == "P2873")
    status, body = api.call(
        "PATCH", "/rest/v1/drivers", token=owner_jwt,
        query={"company_id": "eq." + company, "id": "eq." + driver_a,
               "select": "id"},
        payload={"national_id_back_image_path": driver_path},
    )
    check("driver licence cannot be attached into a national ID field",
          status >= 400 and isinstance(body, dict)
          and body.get("code") == "P2873")
    check("forged attachment does not consume pending or committed quota",
          usage(api, owner_jwt, company) == 0
          and active_reserved(db, company) == 1)
    release(api, owner_jwt, company, driver_path)
    check("negative Driver attachment leaves no reserved capacity",
          active_reserved(db, company) == 0)

    check("document usage starts at zero",
          usage(api, owner_jwt, company) == 0)
    denied(rpc(api, foreign_jwt, "get_company_quota_usage",
               {"p_company_id": company}),
           "P2863", "foreign-tenant quota projection denied")
    denied(rpc(api, viewer_jwt, "get_company_quota_usage",
               {"p_company_id": company}),
           "P2863", "viewer quota projection denied")

    path = name(company, trip)
    denied(reserve(api, viewer_jwt, company, path),
           "P2871", "viewer cannot reserve Trip business documents")
    denied(reserve(api, foreign_jwt, company, path),
           "P2871", "foreign owner cannot reserve this company's documents")
    denied(reserve(api, owner_jwt, other, path),
           "P2871", "company/path mismatch denied")
    check("anonymous reservation denied",
          reserve(api, None, company, path)[0] >= 400)
    check("unreserved raw Storage upload denied",
          storage(api, owner_jwt, "POST", path, DOCUMENT)[0] >= 400)
    check("denied reservations leave quota untouched",
          usage(api, owner_jwt, company) == 0 and active_reserved(db, company) == 0)

    # Idempotent retries reuse the same lease; a different payload with the
    # same operation ID is a hard conflict rather than another quota claim.
    idem_path = name(company, trip)
    idem_op = str(uuid.uuid4())
    status, first_lease = reserve(api, owner_jwt, company,
                                  idem_path, operation=idem_op)
    check("first idempotent reservation succeeds",
          status == 200 and first_lease.get("state") == "reserved")
    status, retried_lease = reserve(api, owner_jwt, company,
                                    idem_path, operation=idem_op)
    check("identical retry returns same reservation, without double count",
          status == 200 and retried_lease == first_lease
          and active_reserved(db, company) == 1)
    denied(reserve(api, owner_jwt, company, name(company, trip),
                   operation=idem_op),
           "P2872", "same idempotency key cannot change upload target")
    release(api, owner_jwt, company, idem_path)
    check("idempotent test release restores available slots",
          active_reserved(db, company) == 0)

    pending = [name(company, trip) for _ in range(49)]
    for item in pending:
        status, body = reserve(api, owner_jwt, company, item)
        check("pending document slot reserved",
              status == 200 and body.get("state") == "reserved")
    check("pending uploads do not become committed usage",
          usage(api, owner_jwt, company) == 0 and active_reserved(db, company) == 49)

    check("fresh active upload reservations are not ready for cleanup",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "f")

    contenders = [name(company, trip), name(company, trip)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(
            lambda path: reserve(api, operations_jwt, company, path),
            contenders,
        ))
    check("only one of two simultaneous last-slot reservations succeeds",
          sum(1 for status, _ in results if status == 200) == 1)
    failed = next(body for status, body in results if status >= 400)
    check("quota contention returned stable typed rejection",
          failed.get("code") == "P2860"
          and failed.get("message") == "quota_business_documents_reached")
    winner_path = contenders[next(
        index for index, (status, _) in enumerate(results) if status == 200
    )]
    denied(reserve(api, owner_jwt, company, name(company, trip)),
           "P2860", "51st business document rejected")
    check("50 reservations are capped without any committed metadata",
          active_reserved(db, company) == 50
          and usage(api, owner_jwt, company) == 0)

    # Turn one pending slot into a committed Trip evidence document.
    chosen = pending[0]
    check("authorized reserved Storage upload",
          storage(api, owner_jwt, "POST", chosen, DOCUMENT)[0] in (200, 201))
    status, created = rpc(api, owner_jwt, "create_trip_document_atomic", {
        "p_company_id": company,
        "p_trip_id": trip,
        "p_document_kind": "waybill",
        "p_storage_reference": chosen,
        "p_original_file_name": "local-proof.pdf",
        "p_mime_type": "application/pdf",
        "p_size_bytes": len(DOCUMENT),
    })
    check("metadata commit atomically consumes the pending reservation",
          status == 200 and isinstance(created, dict)
          and usage(api, owner_jwt, company) == 1
          and active_reserved(db, company) == 49)
    denied(reserve(api, owner_jwt, company, name(company, trip)),
           "P2860", "committed usage plus reservations cannot exceed 50")
    check("foreign tenant cannot download committed object",
          storage(api, foreign_jwt, "GET", chosen)[0] >= 400)
    check("owner can still download existing document after hitting cap",
          storage(api, owner_jwt, "GET", chosen)[0] == 200)

    replacement = name(company, trip)
    status, result = reserve(api, owner_jwt, company, replacement,
                             replacement=chosen)
    check("replace at 50 of 50 does not consume a new slot",
          status == 200 and result.get("state") == "reserved")
    check("reserved replacement may upload",
          storage(api, owner_jwt, "POST", replacement, DOCUMENT)[0] in (200, 201))
    status, replaced = rpc(api, owner_jwt, "replace_trip_document_atomic", {
        "p_company_id": company,
        "p_trip_id": trip,
        "p_document_id": created["id"],
        "p_storage_reference": replacement,
        "p_original_file_name": "local-replacement.pdf",
        "p_mime_type": "application/pdf",
        "p_size_bytes": len(DOCUMENT),
    })
    check("replacement committed without changing occupancy",
          status == 200 and usage(api, owner_jwt, company) == 1)
    check("historical file remains readable (retention)",
          storage(api, owner_jwt, "GET", chosen)[0] == 200)
    deletion_status, _ = storage_remove(api, owner_jwt, replacement)
    survives_status, _ = storage(api, owner_jwt, "GET", replacement)
    check("committed object bytes survive direct Storage delete attempt",
          survives_status == 200)

    for item in pending[1:] + [winner_path]:
        status, _ = release(api, owner_jwt if item in pending else operations_jwt,
                            company, item)
        check("released pending upload does not change committed metadata",
              status in (200, 204))
    check("releasing slots restores free capacity",
          active_reserved(db, company) == 0
          and usage(api, owner_jwt, company) == 1)
    check("direct metadata create remains denied",
          api.call("POST", "/rest/v1/trip_documents", token=owner_jwt,
                   payload={"company_id": company, "trip_id": trip,
                            "document_kind": "waybill",
                            "storage_reference": chosen,
                            "original_file_name": "bypass.pdf",
                            "mime_type": "application/pdf",
                            "size_bytes": len(DOCUMENT)})[0] >= 400)

    status, _ = rpc(api, owner_jwt, "remove_trip_document_atomic", {
        "p_company_id": company, "p_trip_id": trip,
        "p_document_id": replaced["id"],
    })
    check("soft removal releases one live document slot",
          status in (200, 204)
          and usage(api, owner_jwt, company) == 0)
    check("soft-removed object bytes remain protected historical evidence",
          storage(api, owner_jwt, "GET", replacement)[0] == 200)

    # Simulate crash after successful upload but before business metadata
    # commit. Private cleanup claims must not sweep committed/historic files.
    orphan_path = name(company, trip)
    assert_reserved(api, owner_jwt, company, orphan_path)
    check("orphan candidate bytes uploaded successfully",
          storage(api, owner_jwt, "POST", orphan_path, DOCUMENT)[0] in (200, 201))
    status, _ = release(api, owner_jwt, company, orphan_path)
    check("failed/cancelled upload releases pending capacity",
          status in (200, 204) and active_reserved(db, company) == 0)

    status, _ = rpc(api, owner_jwt, "claim_business_document_cleanup",
                    {"p_batch_limit": 25})
    check("client cannot invoke cleanup service RPC", status >= 400)
    psql(db, "UPDATE private.business_document_upload_reservations "
         "SET released_at=now()-interval '20 minutes' "
         "WHERE company_id='" + company + "' AND storage_reference='" +
         orphan_path + "' AND state='released';")

    check("stale unreferenced released file triggers conditional cleanup",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "t")
    status, claimed = api.call(
        "POST", "/rest/v1/rpc/claim_business_document_cleanup",
        admin=True, payload={"p_batch_limit": 25},
    )
    check("only stale and unreferenced reservation is claimable",
          status == 200 and isinstance(claimed, list)
          and len(claimed) == 1
          and claimed[0].get("storage_reference") == orphan_path)
    check("newly claimed work does not cause duplicate HTTP calls",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "f")
    status, _ = storage_remove(api, api.admin, orphan_path, admin=True)
    check("service-owned Storage cleanup removes the orphaned bytes",
          status in (200, 204)
          and storage(api, owner_jwt, "GET", orphan_path)[0] >= 400)
    status, _ = api.call(
        "POST", "/rest/v1/rpc/complete_business_document_cleanup",
        admin=True,
        payload={"p_company_id": company,
                 "p_operation_id": claimed[0]["operation_id"]},
    )
    check("cleanup completion persists a durable terminal record",
          status in (200, 204)
          and psql(db, "SELECT state FROM "
                   "private.business_document_upload_reservations "
                   "WHERE company_id='" + company +
                   "' AND storage_reference='" + orphan_path + "';")
          == "cleaned")
    check("completed cleanup no longer triggers HTTP",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "f")
    check("cleanup cannot consume a live quota slot",
          usage(api, owner_jwt, company) == 0)
    check("cleanup leaves protected historical evidence readable",
          storage(api, owner_jwt, "GET", replacement)[0] == 200)

    # Account deletion must NOT cascade-delete a pending upload ledger row:
    # otherwise Storage bytes uploaded before a crash become untraceable.
    transient_id, transient_jwt = api.create_session("transient", nonce)
    psql(db, "INSERT INTO public.company_users "
         "(company_id,user_id,role,is_active,created_by) VALUES('" +
         company + "','" + transient_id + "','operations',true,'" +
         owner_id + "');")
    abandoned_path = name(company, trip)
    assert_reserved(api, transient_jwt, company, abandoned_path)
    check("transient actor can upload only their reserved object",
          storage(api, transient_jwt, "POST",
                  abandoned_path, DOCUMENT)[0] in (200, 201))
    status, _ = api.call(
        "DELETE", "/auth/v1/admin/users/" + transient_id,
        admin=True,
    )
    check("disposable Auth account removal succeeds", status in (200, 204))
    preserved = psql(
        db, "SELECT coalesce(actor_user_id::text, 'deleted') "
        "FROM private.business_document_upload_reservations "
        "WHERE company_id='" + company + "' "
        "AND storage_reference='" + abandoned_path + "';",
    )
    check("deleted actor retains an unauthenticated cleanup claim",
          preserved == "deleted")
    psql(
        db, "UPDATE private.business_document_upload_reservations "
        "SET created_at=now()-interval '80 minutes', "
        "expires_at=now()-interval '40 minutes' "
        "WHERE company_id='" + company + "' "
        "AND storage_reference='" + abandoned_path + "';",
    )
    check("expired upload from deleted account remains retryable",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "t")
    status, claims = api.call(
        "POST", "/rest/v1/rpc/claim_business_document_cleanup",
        admin=True, payload={"p_batch_limit": 25},
    )
    check("retained orphan is claimable after actor deletion",
          status == 200 and isinstance(claims, list)
          and len(claims) == 1
          and claims[0].get("storage_reference") == abandoned_path)
    status, _ = storage_remove(
        api, api.admin, abandoned_path, admin=True,
    )
    check("orphan object remains removable without its uploading account",
          status in (200, 204))
    status, _ = api.call(
        "POST", "/rest/v1/rpc/complete_business_document_cleanup",
        admin=True,
        payload={"p_company_id": company,
                 "p_operation_id": claims[0]["operation_id"]},
    )
    check("deleted-actor orphan reaches cleaned terminal state",
          status in (200, 204)
          and storage(api, owner_jwt, "GET", abandoned_path)[0] >= 400)

    check("cleanup never calls Edge for terminal historical rows",
          psql(db, "SELECT private.business_document_cleanup_has_work();") == "f")
    check("a separate company retains independent document quota",
          usage(api, foreign_jwt, other) == 0)
    print("PASS Issue #357 disposable signed-JWT document security", flush=True)


if __name__ == "__main__":
    main()
