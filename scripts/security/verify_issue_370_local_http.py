"""Issue #370: real signed-JWT recovery tests on an isolated local stack only.

Reuses the established #365 local GoTrue/PostgREST harness. Never use a
hosted Development or Production project for these fixture mutations.
"""

import json
import secrets

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc, uid


def member(api, jwt, membership_id):
    status, rows = api.call(
        "GET", "/rest/v1/company_users", token=jwt,
        query={"select": "id,role,is_active,updated_at",
               "id": "eq." + membership_id},
    )
    check("platform operator can read recovery target", status == 200
          and isinstance(rows, list) and len(rows) == 1)
    return rows[0]


def recover(api, token, company_id, membership_id, expected,
            role=None, active=None, reason="membership_access_recovery",
            case="HORUS370-LOCAL"):
    return rpc(api, token, "recover_company_membership_as_platform_admin", {
        "p_company_id": company_id,
        "p_membership_id": membership_id,
        "p_new_role": role,
        "p_is_active": active,
        "p_expected_updated_at": expected,
        "p_reason_code": reason,
        "p_case_reference": case,
    })


def denied(label, result, code):
    status, response = result
    check(label, status >= 400 and isinstance(response, dict)
          and response.get("code") == code)


def count_recovery_events(db, company_id, membership_id):
    return int(psql(
        db,
        "SELECT count(*) FROM public.audit_logs "
        "WHERE company_id='" + company_id + "' "
        "AND entity_type='company_user' "
        "AND entity_id='" + membership_id + "' "
        "AND description='platform_membership_recovered';"
    ))


def main():
    url, public, admin_key, db = local_stack()
    api = LocalApi(url, public, admin_key)
    nonce = secrets.token_hex(6)
    accounts = {
        name: api.create_session(name, nonce)
        for name in ("operator", "owner", "member", "foreign_owner")
    }
    operator_id, operator_jwt = accounts["operator"]
    owner_id, owner_jwt = accounts["owner"]
    member_id, _ = accounts["member"]
    foreign_owner_id, foreign_jwt = accounts["foreign_owner"]

    # Test-only setup in the disposable stack; never permit remote endpoints.
    psql(db, "UPDATE public.user_profiles SET is_platform_admin=true "
             "WHERE id='" + operator_id + "';")
    company_a = uid(psql(
        db, "INSERT INTO public.companies(name,base_currency_code,"
        "base_currency_fraction_digits,created_by) "
        "VALUES('HORUS370-" + nonce + "-A','AED',2,'" + owner_id
        + "') RETURNING id;"
    ))
    company_b = uid(psql(
        db, "INSERT INTO public.companies(name,base_currency_code,"
        "base_currency_fraction_digits,created_by) "
        "VALUES('HORUS370-" + nonce + "-B','AED',2,'" + foreign_owner_id
        + "') RETURNING id;"
    ))
    def create_membership(company, person, role):
        return uid(psql(
            db,
            "INSERT INTO public.company_users(company_id,user_id,role,"
            "is_active,created_by) VALUES('"
            + company + "','" + person + "','" + role
            + "',true,'" + person + "') RETURNING id;"
        ))

    owner_membership = create_membership(company_a, owner_id, "owner")
    target_membership = create_membership(company_a, member_id, "accountant")
    create_membership(company_b, foreign_owner_id, "owner")

    check("operator is not a member of target company",
          psql(db, "SELECT count(*) FROM public.company_users WHERE "
               "company_id='" + company_a + "' AND user_id='"
               + operator_id + "';") == "0")

    current = member(api, operator_jwt, target_membership)
    initial_updated_at = current["updated_at"]

    for label, token in (("operator", operator_jwt), ("owner", owner_jwt)):
        status, err = api.call(
            "PATCH", "/rest/v1/company_users", token=token,
            query={"id": "eq." + target_membership},
            payload={"role": "admin"},
        )
        check(label + " direct membership PATCH denied", status in (401, 403)
              and isinstance(err, dict) and err.get("code") == "42501")
    check("no direct-PATCH recovery audit",
          count_recovery_events(db, company_a, target_membership) == 0)

    request = dict(
        company_id=company_a, membership_id=target_membership,
        expected=initial_updated_at, role="admin",
    )
    denied("nonoperator owner recovery refused",
           recover(api, owner_jwt, **request), "P3701")
    denied("foreign owner recovery refused",
           recover(api, foreign_jwt, **request), "P3701")
    status, _ = recover(api, None, **request)
    check("anonymous recovery is refused", status >= 400)
    denied("unrecognized reason rejected",
           recover(api, operator_jwt, **{**request, "reason": "untrusted"}),
           "P3706")
    denied("unsafe case reference rejected",
           recover(api, operator_jwt, **{**request, "case": "bad\nreference"}),
           "P3707")
    denied("wrong tenant and membership pairing denied",
           recover(api, operator_jwt, **{**request, "company_id": company_b}),
           "P3702")
    check("denied paths produced no recovery audit",
          count_recovery_events(db, company_a, target_membership) == 0)

    status, rows = recover(api, operator_jwt, **request)
    check("operator can recover tenant membership",
          status == 200 and isinstance(rows, list) and len(rows) == 1
          and rows[0].get("membership_role") == "admin")
    changed = member(api, operator_jwt, target_membership)
    check("membership recovery persisted", changed["role"] == "admin")

    raw = psql(
        db,
        "SELECT row_to_json(entry)::text FROM "
        "(SELECT actor_user_id,actor_role,actor_email,action,description,"
        "old_values,new_values,metadata FROM public.audit_logs "
        "WHERE company_id='" + company_a + "' AND entity_id='"
        + target_membership + "' "
        "AND description='platform_membership_recovered' "
        "ORDER BY created_at DESC LIMIT 1) AS entry;"
    )
    audit = json.loads(raw)
    check("exactly one non-tenant operator audit",
          count_recovery_events(db, company_a, target_membership) == 1
          and audit.get("actor_user_id") == operator_id
          and audit.get("actor_role") == "platform_admin"
          and audit.get("actor_email") is None)
    check("audit has meaningful old/new + safe reason",
          audit["old_values"] == {"role": "accountant", "is_active": True}
          and audit["new_values"] == {"role": "admin", "is_active": True}
          and audit["metadata"]["reason_code"] == "membership_access_recovery"
          and audit["metadata"]["case_reference"] == "HORUS370-LOCAL")
    denied("optimistic stale snapshot rejected",
           recover(api, operator_jwt, **request), "P3704")
    status, rows = recover(
        api, operator_jwt, company_a, target_membership,
        changed["updated_at"], role="admin")
    check("no-op recovery is idempotent",
          status == 200 and isinstance(rows, list) and len(rows) == 1
          and count_recovery_events(db, company_a, target_membership) == 1)
    check("no-op leaves snapshot unchanged",
          member(api, operator_jwt, target_membership)["updated_at"]
          == changed["updated_at"])

    owner = member(api, operator_jwt, owner_membership)
    denied("last active owner cannot be deactivated",
           recover(api, operator_jwt, company_a, owner_membership,
                   owner["updated_at"], active=False),
           "P3703")
    check("last owner stays active",
          member(api, operator_jwt, owner_membership)["is_active"] is True)

    # Existing SECDEF membership APIs must still work after direct UPDATE revoke.
    status, rows = rpc(api, owner_jwt, "change_company_member_role", {
        "p_company_id": company_a,
        "p_membership_id": target_membership,
        "p_new_role": "viewer",
    })
    check("ordinary owner membership RPC still works", status == 200)
    ordinary = psql(
        db,
        "SELECT count(*) FROM public.audit_logs WHERE company_id='"
        + company_a + "' AND entity_id='" + target_membership
        + "' AND description='company_member_role_changed';"
    )
    check("ordinary RPC audit remains exactly once", ordinary == "1")
    check("operator audit remains exactly once",
          count_recovery_events(db, company_a, target_membership) == 1)
    print("Issue #370 isolated signed-JWT recovery contract: PASS", flush=True)


if __name__ == "__main__":
    main()
