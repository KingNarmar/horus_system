"""Issue #358: signed-JWT operator authorization and entitlement contracts.

Disposable Supabase CLI stack ONLY. Inherits local_stack() safeguards: only
localhost and exactly one local Docker database. Never use hosted credentials.
Secrets, JWTs and MFA enrollment material are never printed.
"""
import base64
import concurrent.futures
import hashlib
import hmac
import json
import secrets
import struct
import time
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc
from verify_issue_354_local_http import onboard, successful_company, denied


PERMISSIONS = (
    "tenant_read", "usage_read", "override_read", "override_write",
    "creation_grant_write", "audit_read", "membership_recovery",
)


def totp(secret, at=None):
    """RFC 6238 TOTP for an isolated, single-use test-only MFA factor."""
    instant = int(time.time() if at is None else at)
    key = base64.b32decode(secret.upper() + "=" * (-len(secret) % 8))
    digest = hmac.new(key, struct.pack(">Q", instant // 30),
                      hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    code = (struct.unpack(">I", digest[offset:offset + 4])[0] &
            0x7FFFFFFF) % 1000000
    return f"{code:06d}"


def elevate_to_aal2(api, aal1_token):
    """Complete a REAL GoTrue TOTP enrollment, challenge and verification."""
    status, enrollment = api.call(
        "POST", "/auth/v1/factors", token=aal1_token,
        payload={"factor_type": "totp", "friendly_name": "HORUS358-LOCAL"}
    )
    if not (status in (200, 201) and isinstance(enrollment, dict)
            and enrollment.get("id")
            and isinstance(enrollment.get("totp"), dict)
            and enrollment["totp"].get("secret")):
        # Only status, field names and error *code*; never print MFA secrets.
        safe_keys = sorted(enrollment.keys()) if isinstance(enrollment, dict) else []
        error_code = enrollment.get("code") if isinstance(enrollment, dict) else None
        raise AssertionError(
            f"TOTP enrollment failed: HTTP {status}, code={error_code}, "
            f"field_names={safe_keys}"
        )
    check("TOTP enrolled with GoTrue", True)
    factor_id = enrollment["id"]
    secret = enrollment["totp"]["secret"]

    status, challenge = api.call(
        "POST", f"/auth/v1/factors/{factor_id}/challenge",
        token=aal1_token, payload={}
    )
    check("TOTP challenge created", status == 200
          and isinstance(challenge, dict) and challenge.get("id"))
    # One optional boundary retry prevents the 30-second clock rollover
    # from creating a fragile CI test.
    for drift in (0, -30, 30):
        status, verified = api.call(
            "POST", f"/auth/v1/factors/{factor_id}/verify",
            token=aal1_token, payload={
                "challenge_id": challenge["id"],
                "code": totp(secret, int(time.time()) + drift)
            }
        )
        if status == 200 and isinstance(verified, dict) and verified.get(
                "access_token"):
            return verified["access_token"]
    raise AssertionError("MFA challenge could not be verified on disposable GoTrue")


def grant(api, jwt, company, revision, kind, key, value, request,
          starts=None, ends=None):
    return rpc(api, jwt, "platform_grant_entitlement_override", {
        "p_company_id": company, "p_scope_kind": kind, "p_scope_key": key,
        "p_value": value, "p_effective_at": starts, "p_expires_at": ends,
        "p_expected_revision": revision, "p_reason":
        "Local signed JWT operator quota validation",
        "p_request_id": request,
    })


def revoke(api, jwt, company, override_id, revision):
    return rpc(api, jwt, "platform_revoke_entitlement_override", {
        "p_company_id": company, "p_override_id": override_id,
        "p_expected_revision": revision,
        "p_reason": "Local signed JWT operator revoke validation",
        "p_request_id": str(uuid.uuid4()),
    })


def effective(api, owner_jwt, company):
    status, body = rpc(api, owner_jwt, "get_company_effective_entitlement",
                       {"p_company_id": company})
    check("owner reads canonical effective entitlement",
          status == 200 and isinstance(body, dict))
    return body


def operator_audit_count(db, company, action):
    return int(psql(db, "SELECT count(*) FROM private.platform_operator_audit "
                    "WHERE company_id='" + company + "' "
                    "AND action='" + action + "';"))


def create_customer(api, jwt, company, name):
    return api.call("POST", "/rest/v1/customers", token=jwt,
                    payload={"company_id": company, "name": name},
                    query={"select": "id"})


def main():
    url, public, admin, db = local_stack()
    api = LocalApi(url, public, admin)
    nonce = secrets.token_hex(6)
    operator_id, aal1 = api.create_session("operator", nonce)
    owner_id, owner_token = api.create_session("owner", nonce)
    foreign_id, foreign_token = api.create_session("foreign", nonce)
    viewer_id, viewer_token = api.create_session("viewer", nonce)

    company = successful_company(
        onboard(api, owner_token, str(uuid.uuid4()), "HORUS358-A-" + nonce),
        "owner company"
    )
    foreign_company = successful_company(
        onboard(api, foreign_token, str(uuid.uuid4()), "HORUS358-B-" + nonce),
        "foreign company"
    )
    psql(db, "INSERT INTO public.company_users("
         "company_id,user_id,role,is_active,created_by) VALUES('"
         + company + "','" + viewer_id + "','viewer',true,'"
         + owner_id + "');")

    # Only disposable DB-owner fixture setup can approve operator status.
    psql(db, "UPDATE public.user_profiles SET is_platform_admin=true "
         "WHERE id='" + operator_id + "';")
    permissions = "ARRAY[" + ",".join("'" + p + "'" for p in PERMISSIONS) + "]::text[]"
    psql(db, "INSERT INTO private.platform_operator_access("
         "user_id,permissions,approved_reason) VALUES('"
         + operator_id + "'," + permissions +
         ",'Approved for isolated signed JWT operator tests');")
    check("operator registry provisioning creates durable audit", psql(
        db, "SELECT count(*) FROM private.platform_operator_audit WHERE "
        "target_user_id='" + operator_id +
        "' AND action='operator_access_created';") == "1")

    directory_args = {
        "p_search": None, "p_after_company_id": None, "p_page_size": 25
    }
    denied(rpc(api, aal1, "platform_list_tenants", directory_args), "42501",
           "platform flag + registry without MFA is NOT enough")
    for role, token in (("owner", owner_token),
                        ("foreign", foreign_token),
                        ("viewer", viewer_token)):
        denied(rpc(api, token, "platform_list_tenants", directory_args),
               "42501", role + " cannot list tenants")
    check("anonymous tenant directory denied",
          rpc(api, None, "platform_list_tenants", directory_args)[0] >= 400)

    aal2 = elevate_to_aal2(api, aal1)
    status, listed = rpc(api, aal2, "platform_list_tenants", directory_args)
    check("verified operator gets minimal directory",
          status == 200 and isinstance(listed, list)
          and any(row.get("company_id") == company for row in listed)
          and all(set(row).issubset({
              "company_id", "company_name", "company_active", "plan_code",
              "subscription_revision", "created_at"
          }) for row in listed))
    check("operator direct tenant SELECT does not bypass RLS",
          api.call("GET", "/rest/v1/companies", token=aal2,
                   query={"select": "id", "id": "eq." + company}) == (200, []))
    check("operator direct subscription SELECT does not bypass RLS",
          api.call("GET", "/rest/v1/company_subscriptions", token=aal2,
                   query={"select": "id", "company_id": "eq." + company})
          == (200, []))
    status, target = rpc(api, aal2, "platform_get_company_usage",
                         {"p_company_id": company})
    check("operator usage projection is scoped and complete",
          status == 200 and target["entitlement"]["plan_code"] == "free_starter"
          and set(target["usage"]) == {
              "company_users", "customers", "drivers", "combined_vehicles",
              "routes", "lifetime_trips", "lifetime_invoices",
              "business_documents"
          })
    denied(rpc(api, owner_token, "platform_get_company_usage",
               {"p_company_id": company}), "42501",
           "company owner cannot access platform usage RPC")

    # Direct table modification of entitlements and operator rights is denied.
    for table, payload in (
        ("company_subscriptions", {"revision": 900}),
        ("user_profiles", {"is_platform_admin": True}),
        ("platform_entitlement_overrides", {"override_value": 999}),
    ):
        status, _ = api.call(
            "PATCH", "/rest/v1/" + table, token=owner_token,
            query={"id": "eq." + str(uuid.uuid4())}, payload=payload
        )
        check("owner direct write denied on " + table, status >= 400)
    denied(grant(api, owner_token, company, 1, "resource",
                 "customers", 12, str(uuid.uuid4())), "42501",
           "owner cannot grant entitlement")

    request_id = str(uuid.uuid4())
    args = (api, aal2, company, 1, "resource", "customers", 12, request_id)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        two = list(pool.map(lambda _: grant(*args), range(2)))
    check("concurrent identical requests are exactly-once and idempotent",
          all(s == 200 for s, _ in two)
          and two[0][1]["override_id"] == two[1][1]["override_id"]
          and two[0][1]["revision"] == 2
          and operator_audit_count(
              db, company, "entitlement_override_granted") == 1)
    denied(grant(api, aal2, company, 1, "resource",
                 "customers", 13, request_id), "P3582",
           "same idempotency key different payload refused")
    denied(grant(api, aal2, company, 1, "resource",
                 "drivers", 9, str(uuid.uuid4())), "P3583",
           "stale subscription revision refused")
    check("owner sees new limit through canonical resolver",
          effective(api, owner_token, company)["limits"]["customers"] == 12)

    for i in range(12):
        status, _ = create_customer(
            api, owner_token, company, f"HORUS358-{nonce}-Customer-{i}"
        )
        check(f"customer slot {i+1} permitted by effective override",
              status == 201)
    status, response = create_customer(
        api, owner_token, company, f"HORUS358-{nonce}-Overcap")
    check("customer slot 13 rejected at server gate",
          status >= 400 and isinstance(response, dict)
          and response.get("code") == "P2860")

    status, revoked = revoke(api, aal2, company, two[0][1]["override_id"], 2)
    check("revoke applied atomically", status == 200
          and revoked["revision"] == 3
          and effective(api, owner_token, company)["limits"]["customers"] == 10)
    check("historical 12 customers survive grant revocation", psql(
        db, "SELECT count(*) FROM public.customers WHERE company_id='"
        + company + "' AND is_active;") == "12")
    check("exactly one grant and revoke audit", operator_audit_count(
        db, company, "entitlement_override_granted") == 1
        and operator_audit_count(
            db, company, "entitlement_override_revoked") == 1)

    # A scheduled grant needs no background job: future checks resolve time.
    expiry = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime(time.time() + 3))
    status, temporary = grant(
        api, aal2, company, 3, "resource", "routes", 12,
        str(uuid.uuid4()), ends=expiry
    )
    check("short temporary grant created", status == 200)
    check("grant temporarily active",
          effective(api, owner_token, company)["limits"]["routes"] == 12)
    time.sleep(4)
    check("expiry reverts only FUTURE route capacity",
          effective(api, owner_token, company)["limits"]["routes"] == 10)

    denied(onboard(api, owner_token, str(uuid.uuid4()),
                   "HORUS358-Unapproved-" + nonce), "P2836",
           "second owner-created company rejected without operator exception")
    grant_args = {
        "p_user_id": owner_id, "p_extra_slots": 1,
        "p_effective_at": None, "p_expires_at": None,
        "p_expected_revision": 0,
        "p_reason": "Approved local test for one additional company",
        "p_request_id": str(uuid.uuid4()),
    }
    status, first_capacity = rpc(
        api, aal2, "platform_set_company_creation_capacity", grant_args
    )
    check("operator authorized one user-scoped creation allowance",
          status == 200 and first_capacity["revision"] == 1)
    newly_created = successful_company(
        onboard(api, owner_token, str(uuid.uuid4()), "HORUS358-C-" + nonce),
        "second company creation after specific operator approval")
    check("new company is distinct", newly_created not in (company,foreign_company))
    grant_args.update({
        "p_extra_slots": 0, "p_expected_revision": 1,
        "p_reason": "Revoke local test for additional company creation",
        "p_request_id": str(uuid.uuid4()),
    })
    status, _ = rpc(
        api, aal2, "platform_set_company_creation_capacity", grant_args)
    check("creation exception revoked", status == 200)
    denied(onboard(api, owner_token, str(uuid.uuid4()),
                   "HORUS358-Third-" + nonce), "P2836",
           "third company refused; historical creations never reset")
    check("creation ledger preserved both companies", psql(
        db, "SELECT count(*) FROM private.company_creation_ledger WHERE "
        "creator_user_id='" + owner_id + "';") == "2")

    # Operator identity is checked from server data EACH time, not a stale
    # role claim. Test same still-valid AAL2 JWT after security revocation.
    psql(db, "UPDATE private.platform_operator_access "
         "SET revoked_at=now(),approved_reason="
         "'Security fixture revoked after authorization tests' "
         "WHERE user_id='" + operator_id + "';")
    denied(rpc(api, aal2, "platform_list_tenants", directory_args), "42501",
           "revoked operator denied despite unchanged JWT")
    check("revocation logged by database trigger", psql(
        db, "SELECT count(*) FROM private.platform_operator_audit WHERE "
        "target_user_id='" + operator_id +
        "' AND action='operator_access_revoked';") == "1")
    print("Issue #358 local-only signed-JWT operator backend: PASS", flush=True)


if __name__ == "__main__":
    main()
