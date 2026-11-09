"""Issue #354: disposable local Free Starter + signed-JWT security contract.

Uses only local Supabase CLI containers and the existing #365 local harness.
Never reads hosted Development / Production credentials.
"""

import concurrent.futures
import secrets
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc, uid


def onboard(api, jwt, request_id, name):
    return rpc(api, jwt, "create_company_with_initial_owner", {
        "p_name": name,
        "p_request_id": request_id,
        "p_business_timezone": "UTC",
        "p_base_currency_code": "AED",
        "p_base_currency_fraction_digits": 2,
        "p_invoice_prefix": "HORUS354",
    })


def successful_company(result, label):
    status, body = result
    rows = body if isinstance(body, list) else [body]
    check(label, status == 200 and len(rows) == 1
          and isinstance(rows[0], dict) and rows[0].get("id"))
    return uid(rows[0]["id"])


def denied(result, code, label):
    status, body = result
    check(label, status >= 400 and isinstance(body, dict)
          and body.get("code") == code)


def count(db, table, condition):
    return int(psql(db, "SELECT count(*) FROM " + table
                    + " WHERE " + condition + ";"))


def entitlement(api, jwt, company):
    return rpc(api, jwt, "get_company_effective_entitlement",
               {"p_company_id": company})


def main():
    url, publishable, admin_key, db = local_stack()
    api = LocalApi(url, publishable, admin_key)
    nonce = secrets.token_hex(7)
    users = {
        role: api.create_session(role, nonce)
        for role in ("owner", "admin", "viewer", "foreign", "racer", "replayer")
    }
    owner_id, owner_jwt = users["owner"]
    owner_request = str(uuid.uuid4())
    company_name = "HORUS354-" + nonce + "-A"

    company = successful_company(
        onboard(api, owner_jwt, owner_request, company_name),
        "real owner JWT creates company"
    )
    check("one Starter grant, no payment/trial simulation",
          count(db, "public.company_subscriptions", "company_id='" + company + "'") == 1
          and psql(db, "SELECT status::text || '|' || "
                       "COALESCE(trial_ends_at::text,'NULL') || '|' || "
                       "COALESCE(external_provider,'NULL') FROM "
                       "public.company_subscriptions WHERE company_id='" + company + "';")
          == "active|NULL|NULL")
    check("one creator allowance ledger record",
          count(db, "private.company_creation_ledger",
                "creator_user_id='" + owner_id + "'") == 1)
    check("four atomic onboarding audit events",
          count(db, "public.audit_logs",
                "company_id='" + company
                + "' AND metadata->>'source'='company_onboarding'") == 4)

    replay = successful_company(
        onboard(api, owner_jwt, owner_request, company_name),
        "same owner+request+payload replay"
    )
    check("retry returns same company without second grant/audit",
          replay == company
          and count(db, "public.company_subscriptions",
                    "company_id='" + company + "'") == 1
          and count(db, "public.audit_logs",
                    "company_id='" + company
                    + "' AND metadata->>'source'='company_onboarding'") == 4)
    denied(onboard(api, owner_jwt, owner_request, company_name + "-changed"),
           "P2838", "same request UUID different payload denied")
    denied(onboard(api, owner_jwt, str(uuid.uuid4()), company_name + "-B"),
           "P2836", "second normal company creation denied")

    # Invitation/active membership is unrelated to original creation allowance.
    for role in ("admin", "viewer"):
        user_id, _ = users[role]
        psql(db, "INSERT INTO public.company_users(company_id,user_id,role,"
                 "is_active,created_by) VALUES('"
                 + company + "','" + user_id + "','" + role
                 + "',true,'" + owner_id + "');")

    status, grant = entitlement(api, owner_jwt, company)
    check("owner reads effective indefinite Starter", status == 200
          and isinstance(grant, dict)
          and grant.get("plan_code") == "free_starter"
          and grant.get("policy_version") == 1
          and grant.get("status") == "active"
          and grant.get("expires_at") is None)
    check("all nine frozen caps and free output capabilities",
          grant["limits"] == {
              "owner_created_companies": 1, "company_users": 3,
              "customers": 10, "drivers": 5, "combined_vehicles": 6,
              "routes": 10, "lifetime_trips": 30,
              "lifetime_invoices": 10, "business_documents": 50,
          } and set(grant["enabled_features"]) == {
              "company_branding", "invoice_pdf", "report_pdf",
              "report_xlsx", "document_upload",
          })

    status, admin_grant = entitlement(api, users["admin"][1], company)
    check("same-company admin reads canonical grant", status == 200
          and admin_grant == grant)
    denied(entitlement(api, users["viewer"][1], company), "P2850",
           "viewer denied full grant")
    denied(entitlement(api, users["foreign"][1], company), "P2850",
           "foreign tenant denied full grant")
    status, _ = entitlement(api, None, company)
    check("unauthenticated grant read denied", status >= 400)

    status, error = api.call(
        "POST", "/rest/v1/company_subscriptions", token=owner_jwt,
        payload={"company_id": company, "plan_id": str(uuid.uuid4())}
    )
    check("owner cannot self-grant plan by REST write",
          status in (401, 403)
          and isinstance(error, dict) and error.get("code") == "42501")

    foreign_id, foreign_jwt = users["foreign"]
    other = successful_company(
        onboard(api, foreign_jwt, str(uuid.uuid4()),
                "HORUS354-" + nonce + "-FOREIGN"),
        "different account retains own company creation allowance"
    )
    check("two tenants have independent Starter grants",
          other != company
          and count(db, "public.company_subscriptions",
                    "company_id IN ('" + company + "','" + other + "')") == 2)
    denied(entitlement(api, owner_jwt, other), "P2850",
           "owner cannot read another company's grant")

    # The server must serialize *distinct* concurrent creation attempts,
    # not merely deduplicate requests that happen to share one UUID.
    racer_id, racer_jwt = users["racer"]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(
            lambda request: onboard(
                api, racer_jwt, request, "HORUS354-" + nonce + "-RACE"
            ),
            [str(uuid.uuid4()), str(uuid.uuid4())]
        ))
    winners = [response for response in results if response[0] == 200]
    losers = [response for response in results if response[0] >= 400]
    check("race of different keys creates exactly one company",
          len(winners) == 1 and len(losers) == 1
          and losers[0][1].get("code") == "P2836"
          and count(db, "private.company_creation_ledger",
                    "creator_user_id='" + racer_id + "'") == 1)

    replay_id, replay_jwt = users["replayer"]
    identical_key = str(uuid.uuid4())
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        matches = list(pool.map(
            lambda _: onboard(api, replay_jwt, identical_key,
                              "HORUS354-" + nonce + "-REPLAY"),
            range(2)
        ))
    ids = [successful_company(item, "concurrent same-key retry")
           for item in matches]
    check("two same-key calls share exactly one company and ledger row",
          ids[0] == ids[1]
          and count(db, "private.company_creation_ledger",
                    "creator_user_id='" + replay_id + "'") == 1)

    # Stale/suspended membership must be rechecked server-side.
    admin_id = users["admin"][0]
    psql(db, "UPDATE public.company_users SET is_active=false WHERE "
             "company_id='" + company + "' AND user_id='" + admin_id + "';")
    denied(entitlement(api, users["admin"][1], company), "P2850",
           "inactive admin JWT cannot read entitlement")

    check("original company never duplicated",
          count(db, "public.companies", "id='" + company + "'") == 1)
    print("Issue #354 disposable signed-JWT contract: PASS", flush=True)


if __name__ == "__main__":
    main()
