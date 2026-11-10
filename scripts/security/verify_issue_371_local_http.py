"""Issue #371: category writes denied, reads and onboarding seed preserved.

Runs only against disposable Supabase CLI local stack. Uses the existing #365
real-GoTrue-JWT HTTP harness; never use hosted Dev/Production credentials.
"""

import secrets
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc, uid


DEFAULT_CATEGORY_COUNT = 11


def create_company(api, jwt, nonce, suffix):
    status, body = rpc(api, jwt, "create_company_with_initial_owner", {
        "p_name": "HORUS371-LOCAL-" + nonce + "-" + suffix,
        "p_request_id": str(uuid.uuid4()),
        "p_business_timezone": "UTC",
        "p_base_currency_code": "AED",
        "p_base_currency_fraction_digits": 2,
        "p_invoice_prefix": "HORUS371",
    })
    rows = body if isinstance(body, list) else [body]
    check("authenticated company onboarding " + suffix,
          status == 200 and len(rows) == 1
          and isinstance(rows[0], dict) and rows[0].get("id"))
    return uid(rows[0]["id"])


def categories(api, jwt, company_id):
    return api.call(
        "GET", "/rest/v1/company_expense_categories", token=jwt,
        query={"select": "id,company_id,code,name,is_active",
               "company_id": "eq." + company_id, "order": "code.asc"},
    )


def deny_category_write(api, jwt, method, category_id, company_id, label, actor_id):
    query = {"select": "id"}
    if method == "PATCH":
        query["id"] = "eq." + category_id

    status, body = api.call(
        method, "/rest/v1/company_expense_categories",
        token=jwt, query=query,
        payload={
            "company_id": company_id,
            "name": "HORUS371-UNAUTHORIZED",
            "code": "horus371_denied",
            "created_by": actor_id,
        },
    )
    check(label + " " + method + " category write denied",
          status in (401, 403)
          and isinstance(body, dict) and body.get("code") == "42501")


def main():
    url, public, service, db = local_stack()
    api = LocalApi(url, public, service)
    nonce = secrets.token_hex(6)
    roles = ("owner", "admin", "accountant", "operations",
             "viewer", "driver", "foreign_owner")
    users = {role: api.create_session(role, nonce) for role in roles}

    owner_id, owner_jwt = users["owner"]
    foreign_id, foreign_jwt = users["foreign_owner"]

    # Both companies are created through the actual signed-JWT onboarding RPC,
    # after all migrations, including #371, have been replayed.
    a = create_company(api, owner_jwt, nonce, "A")
    b = create_company(api, foreign_jwt, nonce, "B")

    for role in ("admin", "accountant", "operations", "viewer", "driver"):
        user_id = users[role][0]
        psql(db,
             "INSERT INTO public.company_users(company_id,user_id,role,"
             "is_active,created_by) VALUES('"
             + a + "','" + user_id + "','" + role
             + "',true,'" + owner_id + "');")

    seed_count = psql(
        db, "SELECT count(*) FROM public.company_expense_categories "
        "WHERE company_id='" + a + "' AND code IS NOT NULL;"
    )
    check("trusted trigger seeds exactly 11 coded categories despite revoked grants",
          seed_count == str(DEFAULT_CATEGORY_COUNT))
    check("second tenant seeds its own categories",
          psql(db, "SELECT count(*) FROM public.company_expense_categories "
               "WHERE company_id='" + b + "' AND code IS NOT NULL;")
          == str(DEFAULT_CATEGORY_COUNT))

    status, rows = categories(api, owner_jwt, a)
    check("owner reads 11 categories with real signed JWT",
          status == 200 and isinstance(rows, list)
          and len(rows) == DEFAULT_CATEGORY_COUNT)
    target = uid(rows[0]["id"])

    for role in ("admin", "accountant", "operations", "viewer"):
        status, data = categories(api, users[role][1], a)
        check(role + " category read preserved",
              status == 200 and isinstance(data, list)
              and len(data) == DEFAULT_CATEGORY_COUNT)

    status, data = categories(api, users["driver"][1], a)
    check("driver cannot read finance category catalogue",
          status == 200 and data == [])
    status, data = categories(api, foreign_jwt, a)
    check("cross-tenant categories filtered by RLS",
          status == 200 and data == [])

    # Every currently signed-in role lacks direct table write grants, even if
    # same-company Owner/Admin/Accountant would pass the old write RLS policy.
    for role in roles:
        user_id, jwt = users[role]
        for method in ("POST", "PATCH"):
            deny_category_write(api, jwt, method, target, a, role, user_id)
    for method in ("POST", "PATCH"):
        deny_category_write(api, None, method, target, a, "anonymous", owner_id)

    check("no unaudited extra category appeared",
          psql(db, "SELECT count(*) FROM public.company_expense_categories "
               "WHERE company_id='" + a + "';") == str(DEFAULT_CATEGORY_COUNT))
    check("existing category remains unchanged after denied PATCH",
          psql(db, "SELECT count(*) FROM public.company_expense_categories "
               "WHERE id='" + target + "' AND name <> 'HORUS371-UNAUTHORIZED';")
          == "1")
    check("no category-changing audit events created from denied writes",
          psql(db, "SELECT count(*) FROM public.audit_logs "
               "WHERE company_id='" + a + "' AND "
               "entity_type='company_expense_category';") == "0")

    check("company expenses write grant preserved",
          psql(db, "SELECT has_table_privilege("
               "'authenticated','public.company_expenses','INSERT') "
               "AND has_table_privilege("
               "'authenticated','public.company_expenses','UPDATE');") == "t")
    check("company expense audit trigger preserved",
          psql(db, "SELECT count(*) FROM pg_catalog.pg_trigger "
               "WHERE tgrelid='public.company_expenses'::regclass "
               "AND tgname='company_expenses_write_server_audit' "
               "AND NOT tgisinternal AND tgenabled <> 'D';") == "1")

    print("Issue #371 isolated signed-JWT category permission contract: PASS",
          flush=True)


if __name__ == "__main__":
    main()
