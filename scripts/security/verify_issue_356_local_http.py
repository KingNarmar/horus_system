"""Issue #356 local-only signed-JWT lifetime quota and idempotency contract.

Runs exclusively against a disposable Supabase CLI stack. Does not connect to
hosted Development or Production, and never prints JWTs or credentials.
"""
import concurrent.futures
import secrets
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc
from verify_issue_354_local_http import onboard, successful_company, denied


def private_count(db, table, company, resource):
    return int(psql(db, "SELECT count(*) FROM private." + table +
                    " WHERE company_id='" + company + "' AND resource='" +
                    resource + "';"))


def used(db, company, resource):
    return int(psql(db, "SELECT used FROM private.company_lifetime_usage_counters "
                    "WHERE company_id='" + company + "' AND resource='" +
                    resource + "';"))


def creation(api, jwt, request, company, customer, route):
    return rpc(api, jwt, "create_trip_idempotent", {
        "p_request_id": request,
        "p_company_id": company,
        "p_customer_id": customer,
        "p_route_id": route,
    })


def draft(api, jwt, request, company, customer, trip, notes=None):
    return rpc(api, jwt, "create_invoice_draft_idempotent", {
        "p_request_id": request,
        "p_company_id": company,
        "p_customer_id": customer,
        "p_trip_ids": [trip],
        "p_discount_minor_units": 0,
        "p_tax_rate_basis_points": 0,
        "p_issue_date": None,
        "p_due_date": None,
        "p_notes": notes,
    })


def successful(result, name):
    status, body = result
    check(name, status == 200 and body is not None)
    return body


def fixture(db, company, suffix):
    customer = psql(
        db, "INSERT INTO public.customers(company_id,name) "
        "VALUES('" + company + "','HORUS356-" + suffix + "') RETURNING id;"
    )
    route = psql(
        db, "INSERT INTO public.routes(company_id,loading_location,"
        "unloading_location) VALUES('" + company + "','HORUS356-Start',"
        "'HORUS356-End') RETURNING id;"
    )
    return customer, route


def main():
    url, public, admin, db = local_stack()
    api = LocalApi(url, public, admin)
    nonce = secrets.token_hex(6)
    actors = {
        role: api.create_session(role, nonce)
        for role in ("owner", "foreign", "operations", "accountant", "viewer")
    }
    owner, owner_jwt = actors["owner"]
    foreign, foreign_jwt = actors["foreign"]
    company = successful_company(
        onboard(api, owner_jwt, str(uuid.uuid4()), "HORUS356-A-" + nonce),
        "trip tenant onboarding"
    )
    other = successful_company(
        onboard(api, foreign_jwt, str(uuid.uuid4()), "HORUS356-B-" + nonce),
        "invoice tenant onboarding"
    )
    for role, target in (("operations", company), ("accountant", other),
                         ("viewer", company)):
        psql(db, "INSERT INTO public.company_users "
             "(company_id,user_id,role,is_active,created_by) VALUES('"
             + target + "','" + actors[role][0] + "','" + role
             + "',true,'" + (owner if target == company else foreign) + "');")

    a_customer, a_route = fixture(db, company, nonce + "-A")
    b_customer, b_route = fixture(db, other, nonce + "-B")
    check("new company lifetime counters are zero",
          all(used(db, c, resource) == 0
              for c in (company, other)
              for resource in ("lifetime_trips", "lifetime_invoices")))

    request = str(uuid.uuid4())
    first_args = (api, owner_jwt, request, company, a_customer, a_route)
    first = successful(creation(*first_args), "first Trip creation")
    replay = successful(creation(*first_args), "same-key Trip replay")
    check("Trip retry returns same id and consumes once",
          replay["id"] == first["id"] and used(db, company, "lifetime_trips") == 1)
    denied(creation(api, owner_jwt, request, company, a_customer, a_route),
           "P9999", "placeholder") if False else None

    different = rpc(api, owner_jwt, "create_trip_idempotent", {
        "p_request_id": request, "p_company_id": company,
        "p_customer_id": a_customer, "p_route_id": a_route,
        "p_notes": "Different payload"
    })
    denied(different, "P2865", "same request ID with different Trip input")
    check("mismatched retry cannot increase usage",
          used(db, company, "lifetime_trips") == 1)

    for role in ("accountant", "viewer"):
        denied(creation(api, actors[role][1], str(uuid.uuid4()),
                        company, a_customer, a_route),
               "P3410", "Trip role " + role + " denied")
    denied(creation(api, foreign_jwt, str(uuid.uuid4()), company,
                    a_customer, a_route),
           "P3410", "foreign member cannot create Trip")
    status, _ = creation(api, None, str(uuid.uuid4()), company,
                         a_customer, a_route)
    check("anonymous Trip denied", status >= 400)

    for _ in range(28):
        successful(creation(api, owner_jwt, str(uuid.uuid4()), company,
                            a_customer, a_route), "within Trip quota")
    check("29 successful Trip creations", used(db, company, "lifetime_trips") == 29)
    prior_audit = int(psql(
        db, "SELECT count(*) FROM public.audit_logs WHERE company_id='"
        + company + "' AND module='trips' AND action='created';"
    ))

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        pair = list(pool.map(
            lambda pair: creation(
                api, actors[pair[0]][1], str(uuid.uuid4()),
                company, a_customer, a_route),
            (("owner", 1), ("operations", 2))
        ))
    successful_count = sum(1 for status, _ in pair if status == 200)
    rejections = [body for status, body in pair if status >= 400]
    check("two different Trip requests contend for last slot",
          successful_count == 1 and len(rejections) == 1
          and rejections[0].get("code") == "P2860"
          and rejections[0].get("message") == "quota_lifetime_trips_reached")
    check("Trip #31 blocked, counter and audit exactly 30",
          used(db, company, "lifetime_trips") == 30
          and private_count(db, "company_lifetime_creation_events",
                            company, "lifetime_trips") == 30
          and int(psql(db, "SELECT count(*) FROM public.audit_logs "
                       "WHERE company_id='" + company +
                       "' AND module='trips' AND action='created';"))
          == prior_audit + 1)
    denied(creation(api, owner_jwt, str(uuid.uuid4()), company,
                    a_customer, a_route),
           "P2860", "Trip #31 denied")
    check("other company Trip quota independent",
          used(db, other, "lifetime_trips") == 0)

    trips = []
    for _ in range(11):
        new_trip = successful(
            creation(api, foreign_jwt, str(uuid.uuid4()),
                     other, b_customer, b_route),
            "invoice fixture Trip creation"
        )
        trips.append(new_trip["id"])
    # Disposable fixture only: mark operational evidence complete and apply
    # a stored freight amount; no hosted database, ledger or app code touched.
    all_ids = ",".join("'" + t + "'" for t in trips)
    psql(db, "BEGIN; SET LOCAL session_replication_role=replica; "
         "UPDATE public.trips SET status='documents_received',"
         "freight_price=100,quantity_tons=1 "
         "WHERE company_id='" + other + "' AND id IN (" + all_ids + "); COMMIT;")

    denied(draft(api, actors["operations"][1], str(uuid.uuid4()),
                 other, b_customer, trips[0]),
           "P2610", "operations cannot create invoice")
    denied(draft(api, owner_jwt, str(uuid.uuid4()), other,
                 b_customer, trips[0]),
           "P2610", "foreign tenant cannot create invoice")
    status, _ = draft(api, None, str(uuid.uuid4()),
                      other, b_customer, trips[0])
    check("anonymous invoice denied", status >= 400)

    invoice_request = str(uuid.uuid4())
    first_invoice = successful(
        draft(api, foreign_jwt, invoice_request, other, b_customer, trips[0]),
        "first invoice draft"
    )
    retried_invoice = successful(
        draft(api, foreign_jwt, invoice_request, other, b_customer, trips[0]),
        "same-key invoice draft retry"
    )
    check("invoice retry preserves ID and counts once",
          first_invoice == retried_invoice
          and used(db, other, "lifetime_invoices") == 1)
    denied(draft(api, foreign_jwt, invoice_request, other,
                 b_customer, trips[0], notes="Different"),
           "P2865", "invoice changed payload retry rejected")

    for trip in trips[1:9]:
        successful(draft(api, foreign_jwt, str(uuid.uuid4()),
                         other, b_customer, trip), "within invoice quota")
    check("nine unique invoice drafts counted",
          used(db, other, "lifetime_invoices") == 9)
    audit_before = int(psql(
        db, "SELECT count(*) FROM public.audit_logs WHERE company_id='"
        + other + "' AND module='invoices' AND action='created';"
    ))
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        pair = list(pool.map(
            lambda pair: draft(
                api, actors[pair[0]][1], str(uuid.uuid4()),
                other, b_customer, pair[1]),
            (("foreign", trips[9]), ("accountant", trips[10]))
        ))
    check("two invoice creates contend for one slot",
          sum(1 for status, _ in pair if status == 200) == 1
          and sum(1 for status, _ in pair if status >= 400) == 1)
    rejected = next(body for status, body in pair if status >= 400)
    check("invoice loser is typed quota rejection",
          rejected.get("code") == "P2860"
          and rejected.get("message") == "quota_lifetime_invoices_reached")
    check("ten lifetime invoices, no rejected audit",
          used(db, other, "lifetime_invoices") == 10
          and private_count(db, "company_lifetime_creation_events",
                            other, "lifetime_invoices") == 10
          and int(psql(db, "SELECT count(*) FROM public.audit_logs "
                       "WHERE company_id='" + other +
                       "' AND module='invoices' AND action='created';"))
          == audit_before + 1)

    status, _ = rpc(api, foreign_jwt, "update_invoice_draft", {
        "p_company_id": other,
        "p_invoice_id": first_invoice, "p_customer_id": b_customer,
        "p_trip_ids": [trips[0]], "p_discount_minor_units": 0,
        "p_tax_rate_basis_points": 0, "p_issue_date": None,
        "p_due_date": None, "p_notes": "Approved after lifetime cap"
    })
    check("editing existing invoice after quota remains allowed", status == 200)
    status, _ = rpc(api, foreign_jwt, "cancel_invoice", {
        "p_company_id": other, "p_invoice_id": first_invoice,
        "p_reason": "Local-only correction"
    })
    check("cancelling existing draft allowed after cap", status == 200)
    check("cancellation never restores lifetime invoice quota",
          used(db, other, "lifetime_invoices") == 10)

    status, data = rpc(api, foreign_jwt, "get_company_quota_usage", {
        "p_company_id": other
    })
    check("canonical projection returns monotonic totals",
          status == 200 and data["usage"]["lifetime_trips"] == 11
          and data["usage"]["lifetime_invoices"] == 10)
    check("cross-tenant quota stays independent",
          used(db, company, "lifetime_invoices") == 0)
    print("Issue #356 disposable signed-JWT lifetime security PASS", flush=True)


if __name__ == "__main__":
    main()
