"""Issue #32: disposable local signed-JWT quota contract.

Never contacts or modifies hosted Supabase. Uses the existing local #365 harness.
All fixtures are isolated to the disposable Supabase CLI stack.
"""
import concurrent.futures
import hashlib
import hmac
import secrets
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql, rpc, uid
from verify_issue_354_local_http import onboard, successful_company, denied


def count(db, table, company, extra=""):
    where = "company_id='" + company + "'" + extra
    return int(psql(db, "SELECT count(*) FROM public." + table
                    + " WHERE " + where + ";"))


def prepare(api, jwt, company, email, role="viewer"):
    token_hash = "\\x" + hashlib.sha256(secrets.token_bytes(32)).hexdigest()
    return token_hash, rpc(api, jwt, "prepare_company_invitation", {
        "p_company_id": company, "p_email": email,
        "p_role": role, "p_token_hash": token_hash,
    })


def one_row(response, label):
    status, body = response
    rows = body if isinstance(body, list) else [body]
    check(label, status in (200, 201) and len(rows) == 1
          and isinstance(rows[0], dict))
    return rows[0]


def quota(api, jwt, company):
    return rpc(api, jwt, "get_company_quota_usage", {"p_company_id": company})


def fleet(api, jwt, company, table, plate, active=True):
    return api.call("POST", "/rest/v1/" + table, token=jwt, payload={
        "company_id": company, "plate_number": plate, "is_active": active,
    })


def active_fleet(db, company):
    return (count(db, "tractor_heads", company, " AND is_active=true")
            + count(db, "trailers", company, " AND is_active=true"))


def membership(db, company, user_id, role, creator):
    psql(db, "INSERT INTO public.company_users"
         "(company_id,user_id,role,is_active,created_by) VALUES('"
         + company + "','" + user_id + "','" + role + "',true,'"
         + creator + "');")


def main():
    url, public, admin_key, db = local_stack()
    api = LocalApi(url, public, admin_key)
    nonce = secrets.token_hex(7)
    actors = {
        name: api.create_session(name, nonce)
        for name in ("owner", "invitee", "admin", "operations", "accountant",
                     "viewer", "driver", "foreign", "operator", "legacy", "legacy_member_a",
                     "legacy_member_b", "legacy_member_c")
    }
    owner_id, owner_jwt = actors["owner"]
    foreign_id, foreign_jwt = actors["foreign"]
    operator_id, operator_jwt = actors["operator"]
    psql(db, "UPDATE public.user_profiles SET is_platform_admin=true "
             "WHERE id='" + operator_id + "';")
    company = successful_company(
        onboard(api, owner_jwt, str(uuid.uuid4()), "HORUS32-" + nonce),
        "owner creates test company through canonical #354 RPC",
    )
    foreign_company = successful_company(
        onboard(api, foreign_jwt, str(uuid.uuid4()), "HORUS32-OTHER-" + nonce),
        "foreign tenant has its own Starter contract",
    )

    result = one_row(quota(api, owner_jwt, company), "owner quota projection")
    check("canonical grant and initial Owner seat are authoritative",
          result["entitlement"]["plan_code"] == "free_starter"
          and result["usage"]["company_users"] == 1
          and result["usage"]["combined_vehicles"] == 0
          and result["entitlement"]["limits"]["company_users"] == 3
          and result["entitlement"]["limits"]["combined_vehicles"] == 6)
    denied(quota(api, foreign_jwt, company), "P2863",
           "other tenant cannot query company usage")
    status, _ = quota(api, None, company)
    check("anonymous user cannot read quota", status >= 400)

    # Pending invitation occupies one seat; accepting swaps it for membership.
    invitee_email = "horus365-invitee-" + nonce + "@example.test"
    token, attempt = prepare(api, owner_jwt, company, invitee_email)
    one_row(attempt, "first invited seat reserved")
    check("unconfirmed prepare reserves capacity",
          one_row(quota(api, owner_jwt, company), "pending usage read")
          ["usage"]["company_users"] == 2)
    accepted = one_row(
        rpc(api, actors["invitee"][1], "accept_company_invitation",
            {"p_token_hash": token}),
        "invited signed-JWT user accepts existing reserved seat",
    )
    check("membership maps to the invitee",
          accepted["company_id"] == company)
    check("invitation acceptance does not double count a seat",
          one_row(quota(api, owner_jwt, company), "post-accept snapshot")
          ["usage"]["company_users"] == 2)
    replay = one_row(
        rpc(api, actors["invitee"][1], "accept_company_invitation",
            {"p_token_hash": token}),
        "acceptance retry is idempotent",
    )
    check("retry reuses the same membership",
          replay["membership_id"] == accepted["membership_id"])

    # Two independent prepares contend for the final seat.
    emails = [f"horus32-race-{i}-{nonce}@example.test" for i in range(2)]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        competing = list(pool.map(
            lambda mail: prepare(api, owner_jwt, company, mail)[1],
            emails,
        ))
    winners = [r for r in competing if r[0] == 200]
    losers = [r for r in competing if r[0] >= 400]
    check("concurrent distinct invites allocate exactly one final seat",
          len(winners) == 1 and len(losers) == 1
          and losers[0][1].get("code") == "P2860")
    pending_id = one_row(winners[0], "winning invite ID")["invitation_id"]
    check("invitation capacity never exceeds 3",
          one_row(quota(api, owner_jwt, company), "after invite race")
          ["usage"]["company_users"] == 3)
    one_row(
        rpc(api, owner_jwt, "revoke_company_invitation", {
            "p_company_id": company, "p_invitation_id": pending_id
        }),
        "revoke winning invitation",
    )
    check("revoked invitation immediately frees a seat",
          one_row(quota(api, owner_jwt, company), "after revoke")
          ["usage"]["company_users"] == 2)

    # A definite first-send rejection needs proof and must release a seat.
    token, first_attempt = prepare(
        api, owner_jwt, company, f"horus32-abort-{nonce}@example.test"
    )
    preparation = one_row(first_attempt, "prepare definitely rejected send")
    proof_secret = "horus32-local-only-confirmation-secret-" + nonce
    key_hash = hashlib.sha256(proof_secret.encode()).digest()
    psql(db,
         "INSERT INTO private.company_invitation_confirmation_keys"
         "(singleton,key_hash) VALUES(true,decode('"
         + key_hash.hex() + "','hex'));")
    message = (company + ":" + preparation["invitation_id"] + ":"
               + preparation["delivery_attempt_id"] + ":abort_initial")
    proof = "\\x" + hmac.new(
        key_hash, message.encode(), hashlib.sha256
    ).hexdigest()
    invalid_proof = "\\x" + "00" * 32
    abort_args = {
        "p_company_id": company,
        "p_invitation_id": preparation["invitation_id"],
        "p_delivery_attempt_id": preparation["delivery_attempt_id"],
        "p_confirmation_proof": invalid_proof,
    }
    denied(rpc(api, owner_jwt, "abort_company_invitation_initial", abort_args),
           "P2813", "direct caller cannot forge initial delivery rejection")
    abort_args["p_confirmation_proof"] = proof
    status, _ = rpc(api, owner_jwt, "abort_company_invitation_initial", abort_args)
    check("signed explicit initial rejection is accepted", status in (200, 204))
    check("rejected new invitation no longer reserves capacity",
          one_row(quota(api, owner_jwt, company), "after abort")
          ["usage"]["company_users"] == 2)

    # Simultaneous initial confirmation and signed rejection: exactly one wins.
    token, race_attempt = prepare(
        api, owner_jwt, company, f"horus32-confirm-abort-{nonce}@example.test"
    )
    delivery = one_row(race_attempt, "reserve confirm/abort race seat")
    def delivery_proof(action):
        payload = (company + ":" + delivery["invitation_id"] + ":"
                   + delivery["delivery_attempt_id"] + ":" + action)
        return "\\x" + hmac.new(
            key_hash, payload.encode(), hashlib.sha256
        ).hexdigest()

    base_args = {
        "p_company_id": company,
        "p_invitation_id": delivery["invitation_id"],
        "p_delivery_attempt_id": delivery["delivery_attempt_id"],
    }
    audit_before_race = count(db, "audit_logs", company)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        confirm_abort = list(pool.map(
            lambda action: rpc(
                api, owner_jwt,
                "confirm_company_invitation_delivery"
                if action == "confirm" else "abort_company_invitation_initial",
                {**base_args, "p_confirmation_proof": delivery_proof(action)},
            ),
            ("confirm", "abort_initial"),
        ))
    winners = [x for x in confirm_abort if x[0] in (200, 201, 204)]
    losers = [x for x in confirm_abort if x[0] >= 400]
    check("confirm vs initial abort has one atomic winner",
          len(winners) == 1 and len(losers) == 1)
    final = psql(
        db, "SELECT status::text || ':' || send_count FROM "
        "public.company_invitations WHERE id='"
        + delivery["invitation_id"] + "';"
    )
    check("race leaves one valid terminal result",
          final in ("pending:1", "revoked:0"))
    check("race writes exactly one finalization audit",
          count(db, "audit_logs", company) == audit_before_race + 1)
    one_row(rpc(api, owner_jwt, "revoke_company_invitation", {
        "p_company_id": company,
        "p_invitation_id": delivery["invitation_id"],
    }), "race result cleanup")
    check("confirm/abort cleanup restores seat usage",
          one_row(quota(api, owner_jwt, company), "race cleanup usage")
          ["usage"]["company_users"] == 2)

    # Expired original invitation plus live staged resend still holds a seat.
    _, send_attempt = prepare(
        api, owner_jwt, company, f"horus32-staged-{nonce}@example.test"
    )
    staged = one_row(send_attempt, "prepare staged resend fixture")
    candidate = "\\x" + hashlib.sha256(secrets.token_bytes(32)).hexdigest()
    one_row(
        rpc(api, owner_jwt, "prepare_company_invitation_resend", {
            "p_company_id": company,
            "p_invitation_id": staged["invitation_id"],
            "p_token_hash": candidate,
        }),
        "prepare valid resend candidate",
    )
    psql(db,
         "UPDATE public.company_invitations SET expires_at=now()-"
         "interval '1 minute' WHERE id='" + staged["invitation_id"] + "';")
    check("live resend candidate continues to reserve a seat",
          one_row(quota(api, owner_jwt, company), "staged resend quota")
          ["usage"]["company_users"] == 3)
    one_row(
        rpc(api, owner_jwt, "revoke_company_invitation", {
            "p_company_id": company,
            "p_invitation_id": staged["invitation_id"],
        }),
        "revoke expired original with live staged resend",
    )
    check("staged resend revocation clears seat",
          one_row(quota(api, owner_jwt, company), "resend revocation quota")
          ["usage"]["company_users"] == 2)

    # Reactivation must consume a seat even when a prior membership exists.
    waiting_a = one_row(
        prepare(api, owner_jwt, company,
                f"horus32-reserved-a-{nonce}@example.test")[1],
        "reserve seat before member deactivation",
    )
    member_args = {
        "p_company_id": company, "p_membership_id": accepted["membership_id"],
    }
    one_row(rpc(api, owner_jwt, "deactivate_company_member", member_args),
            "deactivate existing membership frees active seat")
    waiting_b = one_row(
        prepare(api, owner_jwt, company,
                f"horus32-reserved-b-{nonce}@example.test")[1],
        "two live pending reservations fill all seats",
    )
    denied(rpc(api, owner_jwt, "reactivate_company_member", member_args),
           "P2860", "reactivation denied while reserved capacity is full")
    membership_id = accepted["membership_id"]
    expected_update = psql(
        db, "SELECT updated_at FROM public.company_users WHERE id='"
        + membership_id + "';"
    )
    operator_request = {
        "p_company_id": company,
        "p_membership_id": membership_id,
        "p_new_role": None,
        "p_is_active": True,
        "p_expected_updated_at": expected_update,
        "p_reason_code": "membership_access_recovery",
        "p_case_reference": "HORUS32-CAP",
    }
    audit_before_operator = count(db, "audit_logs", company)
    denied(
        rpc(api, operator_jwt,
            "recover_company_membership_as_platform_admin",
            operator_request),
        "P2860", "operator recovery cannot activate without quota override",
    )
    check("denied operator recovery leaves member inactive and no audit",
          psql(db, "SELECT is_active FROM public.company_users WHERE id='"
               + membership_id + "';") == "f"
          and count(db, "audit_logs", company) == audit_before_operator)
    one_row(
        rpc(api, owner_jwt, "revoke_company_invitation", {
            "p_company_id": company,
            "p_invitation_id": waiting_b["invitation_id"],
        }),
        "revoke pending seat before reactivation",
    )
    restored = one_row(
        rpc(api, operator_jwt,
            "recover_company_membership_as_platform_admin",
            operator_request),
        "operator recovery allowed after capacity is freed",
    )
    check("operator recovery activates without exceeding company quota",
          restored["membership_active"] is True
          and one_row(quota(api, owner_jwt, company), "operator recovery quota")
          ["usage"]["company_users"] == 3)
    one_row(rpc(api, owner_jwt, "reactivate_company_member", member_args),
            "ordinary reactivation remains idempotent after recovery")
    one_row(
        rpc(api, owner_jwt, "revoke_company_invitation", {
            "p_company_id": company,
            "p_invitation_id": waiting_a["invitation_id"],
        }),
        "cleanup reserved seat after reactivation",
    )
    check("member reactivation and revoked invites preserve original usage",
          one_row(quota(api, owner_jwt, company), "seat lifecycle snapshot")
          ["usage"]["company_users"] == 2)

    # Signed REST bypass and cross-table contention: five assets then race.
    for i in range(5):
        table = "tractor_heads" if i % 2 == 0 else "trailers"
        one_row(fleet(api, owner_jwt, company, table,
                      "Q32-" + str(i) + "-" + nonce),
                "authorized REST fleet fixture")
    check("both asset tables combine to five", active_fleet(db, company) == 5)
    audit_before = count(db, "audit_logs", company)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(
            lambda i: fleet(
                api, owner_jwt, company,
                "tractor_heads" if i == 0 else "trailers",
                "Q32-RACE-" + str(i) + "-" + nonce,
            ), range(2)
        ))
    fleet_winners = [r for r in results if r[0] == 201]
    fleet_losers = [r for r in results if r[0] >= 400]
    check("tractor vs trailer race allows exactly one remaining vehicle",
          len(fleet_winners) == 1 and len(fleet_losers) == 1
          and fleet_losers[0][1].get("code") == "P2860"
          and active_fleet(db, company) == 6)
    check("failed insert creates no extra audit entry",
          count(db, "audit_logs", company) == audit_before + 1)
    denied(fleet(api, owner_jwt, company, "trailers",
                 "Q32-EXTRA-" + nonce),
           "P2860", "direct API cannot bypass full combined capacity")

    # Inactive assets can exist at capacity, but reactivation acquires a slot.
    parked = one_row(
        fleet(api, owner_jwt, company, "trailers",
              "Q32-INACTIVE-" + nonce, active=False),
        "inactive historical asset allowed",
    )
    parked_id = parked["id"]
    check("inactive insert does not consume capacity",
          active_fleet(db, company) == 6)
    status, data = api.call(
        "PATCH", "/rest/v1/trailers", token=owner_jwt,
        query={"id": "eq." + parked_id, "company_id": "eq." + company},
        payload={"is_active": True},
    )
    check("false->true update is rejected at capacity",
          status >= 400 and isinstance(data, dict)
          and data.get("code") == "P2860")

    # Existing edits and financial closeout must not be blocked by a full cap.
    # Always use a known fixture row from tractor_heads for read/update verification.
    status, rows = api.call(
        "GET", "/rest/v1/tractor_heads", token=owner_jwt,
        query={"company_id": "eq." + company, "limit": "1"},
    )
    check("existing fleet records remain readable", status == 200 and bool(rows))
    current_id = rows[0]["id"]
    status, _ = api.call(
        "PATCH", "/rest/v1/tractor_heads", token=owner_jwt,
        query={"company_id": "eq." + company, "id": "eq." + current_id},
        payload={"notes": "Authorized maintenance edit at limit"},
    )
    check("non-consuming edit remains allowed", status == 200)

    # Multi-row REST requests must fail atomically, without partial writes.
    status, active_trailers = api.call(
        "GET", "/rest/v1/trailers", token=owner_jwt,
        query={"company_id": "eq." + company, "is_active": "eq.true",
               "limit": "1"},
    )
    check("active trailer fixture exists for capacity release",
          status == 200 and bool(active_trailers))
    active_trailer_id = active_trailers[0]["id"]
    for table_name, asset_id in [
        ("tractor_heads", current_id), ("trailers", active_trailer_id),
    ]:
        status, _ = api.call(
            "PATCH", "/rest/v1/" + table_name, token=owner_jwt,
            query={"company_id": "eq." + company, "id": "eq." + asset_id},
            payload={"is_active": False},
        )
        check("deactivation releases active vehicle capacity", status == 200)
    check("two deactivations free exactly two shared slots",
          active_fleet(db, company) == 4)
    audit_before_bulk = count(db, "audit_logs", company)
    status, payload = api.call(
        "POST", "/rest/v1/trailers", token=owner_jwt,
        payload=[
            {"company_id": company,
             "plate_number": "Q32-BULK-" + str(i) + "-" + nonce}
            for i in range(3)
        ],
    )
    check("three-row insertion cannot exceed only two free vehicle slots",
          status >= 400 and isinstance(payload, dict)
          and payload.get("code") == "P2860"
          and active_fleet(db, company) == 4)
    check("failed bulk write generates no partial audit rows",
          count(db, "audit_logs", company) == audit_before_bulk)
    for table_name, asset_id in [
        ("tractor_heads", current_id), ("trailers", active_trailer_id),
    ]:
        status, _ = api.call(
            "PATCH", "/rest/v1/" + table_name, token=owner_jwt,
            query={"company_id": "eq." + company, "id": "eq." + asset_id},
            payload={"is_active": True},
        )
        check("reactivation uses restored shared capacity", status == 200)
    check("all restored assets fit the same 6-vehicle cap",
          active_fleet(db, company) == 6)

    # Roles, tenant boundaries and company_id mutation are DB-enforced.
    membership(db, company, actors["admin"][0], "admin", owner_id)
    membership(db, company, actors["operations"][0], "operations", owner_id)
    membership(db, company, actors["accountant"][0], "accountant", owner_id)
    membership(db, company, actors["viewer"][0], "viewer", owner_id)
    membership(db, company, actors["driver"][0], "driver", owner_id)
    check("legacy over-cap members are kept intact",
          one_row(quota(api, owner_jwt, company), "historical occupancy")
          ["usage"]["company_users"] == 7)
    check("admin may see own usage",
          quota(api, actors["admin"][1], company)[0] == 200)
    for role in ("operations", "accountant", "viewer", "driver"):
        denied(quota(api, actors[role][1], company), "P2863",
               role + " cannot read full usage")
    denied(fleet(api, actors["operations"][1], company, "trailers",
                 "Q32-OPS-CAP-" + nonce),
           "P2860", "operations may manage Fleet but cannot exceed capacity")
    for role in ("accountant", "viewer", "driver", "foreign"):
        status, failure = fleet(api, actors[role][1], company, "trailers",
                                "Q32-DENIED-" + role + "-" + nonce)
        check(role + " denied before any private quota is inspected",
              status >= 400 and isinstance(failure, dict)
              and failure.get("code") == "42501")

    membership(db, foreign_company, owner_id, "admin", foreign_id)
    status, result = api.call(
        "PATCH", "/rest/v1/tractor_heads", token=owner_jwt,
        query={"company_id": "eq." + company, "id": "eq." + current_id},
        payload={"company_id": foreign_company},
    )
    check("asset company reassignment denied even for member of both tenants",
          status >= 400 and isinstance(result, dict)
          and result.get("code") == "P2864")
    denied(
        prepare(api, owner_jwt, company, f"over-cap-{nonce}@example.test")[1],
        "P2860", "legacy over-cap tenant cannot add reserved seat",
    )
    status, _ = rpc(api, owner_jwt, "change_company_member_role", {
        "p_company_id": company,
        "p_membership_id": uid(psql(
            db, "SELECT id FROM public.company_users WHERE company_id='"
            + company + "' AND user_id='" + actors["viewer"][0] + "';"
        )),
        "p_new_role": "accountant",
    })
    check("over-cap company can edit an existing role", status == 200)

    psql(db, "UPDATE public.company_users SET is_active=false WHERE company_id='"
         + company + "' AND user_id='" + actors["operations"][0] + "';")
    status, _ = fleet(api, actors["operations"][1], company,
                      "trailers", "Q32-SUSPENDED-" + nonce)
    check("deactivated member token loses access immediately", status >= 400)
    print("Issue #32 disposable signed-JWT quota contract: PASS", flush=True)


if __name__ == "__main__":
    main()
