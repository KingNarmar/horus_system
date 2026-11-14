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


def storage_remove(api, jwt, path):
    """Use Storage API's batch DELETE endpoint, not an unsupported URL."""
    url = api.url + "/storage/v1/object/business-documents"
    headers = {
        "apikey": api.public,
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

    customer, route = fixture(db, company, nonce)
    trip = successful(
        creation(api, owner_jwt, str(uuid.uuid4()),
                 company, customer, route),
        "Trip quota fixture",
    )["id"]

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

    pending = [name(company, trip) for _ in range(49)]
    for item in pending:
        status, body = reserve(api, owner_jwt, company, item)
        check("pending document slot reserved",
              status == 200 and body.get("state") == "reserved")
    check("pending uploads do not become committed usage",
          usage(api, owner_jwt, company) == 0 and active_reserved(db, company) == 49)

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
    check("committed object cannot be deleted through direct Storage",
          storage_remove(api, owner_jwt, replacement)[0] >= 400
          and storage(api, owner_jwt, "GET", replacement)[0] == 200)

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

    check("a separate company retains independent document quota",
          usage(api, foreign_jwt, other) == 0)
    print("PASS Issue #357 disposable signed-JWT document security", flush=True)


if __name__ == "__main__":
    main()
