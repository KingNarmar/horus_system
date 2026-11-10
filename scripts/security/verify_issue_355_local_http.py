"""Issue #355: signed-JWT active resource quota contract on disposable local Supabase.

Never connects to hosted Development or Production. The local stack is recreated
from versioned migrations and disposable test users/companies.
"""
import concurrent.futures
import secrets
import uuid

from verify_issue_365_local_http import LocalApi, check, local_stack, psql
from verify_issue_354_local_http import onboard, successful_company
from verify_issue_32_local_http import count, membership, quota


def record(resource, company, name, active=True):
    common = {"company_id": company, "is_active": active}
    if resource == "customers":
        return {**common, "name": name}
    if resource == "drivers":
        return {**common, "name": name, "full_name": name}
    return {**common, "loading_location": name,
            "unloading_location": "Destination " + name}


def write(api, jwt, resource, company, name, active=True):
    return api.call("POST", "/rest/v1/" + resource, token=jwt,
                    payload=record(resource, company, name, active))


def edit(api, jwt, resource, company, row_id, values):
    return api.call("PATCH", "/rest/v1/" + resource, token=jwt,
                    query={"id": "eq." + row_id, "company_id": "eq." + company},
                    payload=values)


def row(result, label):
    code, payload = result
    check(label, code == 201 and isinstance(payload, (list, dict)))
    if isinstance(payload, list):
        check(label + ": exactly one row", len(payload) == 1)
        return payload[0]
    return payload


def denied_quota(result, code, label):
    status, payload = result
    check(label, status >= 400 and isinstance(payload, dict)
          and payload.get("code") == "P2860"
          and payload.get("message") == code)


def main():
    url, publishable, service, db = local_stack()
    api = LocalApi(url, publishable, service)
    nonce = secrets.token_hex(6)
    actors = {
        role: api.create_session(role, nonce)
        for role in ("owner", "foreign", "admin", "operations",
                     "viewer", "accountant", "driver", "suspended")
    }
    owner_id, owner_jwt = actors["owner"]
    foreign_jwt = actors["foreign"][1]
    company = successful_company(
        onboard(api, owner_jwt, str(uuid.uuid4()), "HORUS355-" + nonce),
        "tenant with free-starter quota",
    )
    foreign_company = successful_company(
        onboard(api, foreign_jwt, str(uuid.uuid4()), "HORUS355-B-" + nonce),
        "second independent tenant",
    )

    for role in ("admin", "operations", "viewer", "accountant",
                 "driver", "suspended"):
        membership(db, company, actors[role][0],
                   "viewer" if role == "suspended" else role, owner_id)
    psql(db, "UPDATE public.company_users SET is_active=false "
         "WHERE company_id='" + company + "' AND user_id='"
         + actors["suspended"][0] + "';")

    status, response = quota(api, owner_jwt, company)
    check("quota read available", status == 200
          and isinstance(response, (list, dict)))
    state = response[0] if isinstance(response, list) else response
    for resource, cap in [("customers", 10), ("drivers", 5), ("routes", 10)]:
        check("canonical server entitlement " + resource,
              state["entitlement"]["limits"][resource] == cap
              and state["usage"][resource] == 0)

    for resource, cap in [("customers", 10), ("drivers", 5), ("routes", 10)]:
        code = "quota_" + resource + "_reached"
        prefix = "355-" + resource + "-" + nonce
        # RLS guards apply even when quota is not yet full.
        for role in ("viewer", "accountant", "driver", "suspended"):
            result = write(api, actors[role][1], resource, company,
                           prefix + "-" + role)
            check(resource + " disallows unauthorized role " + role,
                  result[0] >= 400)
        check(resource + " disallows signed foreign company member",
              write(api, foreign_jwt, resource, company, prefix + "-foreign")[0]
              >= 400)
        check(resource + " disallows anonymous client",
              write(api, None, resource, company, prefix + "-anonymous")[0]
              >= 400)
        check(resource + " unauthorized writes leave zero rows",
              count(db, resource, company, " AND is_active=true") == 0)

        # Owner/Admin/Operations all use the authorized direct REST path.
        writer = [owner_jwt, actors["admin"][1], actors["operations"][1]]
        active_rows = []
        for i in range(cap - 1):
            result = write(api, writer[i % 3], resource, company,
                           prefix + "-active-" + str(i))
            active_rows.append(row(result, resource + " allowed creation"))

        audit_before = count(db, "audit_logs", company)
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
            race = list(pool.map(
                lambda i: write(api, writer[i + 1], resource, company,
                                prefix + "-race-" + str(i)),
                range(2),
            ))
        winners = [r for r in race if r[0] == 201]
        losers = [r for r in race if r[0] >= 400]
        check(resource + " race allows exactly one final slot",
              len(winners) == 1 and len(losers) == 1)
        denied_quota(losers[0], code, resource + " correct SQLSTATE")
        check(resource + " cannot exceed cap",
              count(db, resource, company, " AND is_active=true") == cap)
        check(resource + " denied race adds no audit",
              count(db, "audit_logs", company) == audit_before + 1)

        denied_quota(
            write(api, owner_jwt, resource, company, prefix + "-extra"),
            code, resource + " retry after full capacity",
        )
        parked = row(
            write(api, owner_jwt, resource, company,
                  prefix + "-parked", active=False),
            resource + " inactive import does not consume capacity",
        )
        check(resource + " inactive record is retained",
              count(db, resource, company, " AND is_active=false") >= 1)
        denied_quota(
            edit(api, owner_jwt, resource, company,
                 parked["id"], {"is_active": True}),
            code, resource + " reactivation also quota-gated",
        )

        # Edits are not quota-consuming, and disabled records remain accessible.
        edit_field = ("name" if resource == "customers" else
                      "notes" if resource == "drivers" else "notes")
        check(resource + " non-consuming edit remains allowed",
              edit(api, owner_jwt, resource, company,
                   active_rows[0]["id"],
                   {edit_field: "Approved " + prefix})[0] == 200)
        check(resource + " deactivation releases capacity",
              edit(api, owner_jwt, resource, company,
                   active_rows[0]["id"], {"is_active": False})[0] == 200)
        check(resource + " allows only one reactivation in freed capacity",
              edit(api, owner_jwt, resource, company,
                   parked["id"], {"is_active": True})[0] == 200)
        check(resource + " no active count drift after restore",
              count(db, resource, company, " AND is_active=true") == cap)
        check(resource + " company reassignment forbidden",
              edit(api, owner_jwt, resource, company,
                   parked["id"], {"company_id": foreign_company})[0] >= 400)

        check(resource + " other tenant capacity is isolated",
              write(api, foreign_jwt, resource, foreign_company,
                    prefix + "-tenantB")[0] == 201)
        check(resource + " tenant B has independent count",
              count(db, resource, foreign_company, " AND is_active=true") == 1)
        status, rows = api.call("GET", "/rest/v1/" + resource,
                                token=owner_jwt,
                                query={"company_id": "eq." + company,
                                       "limit": "2"})
        check(resource + " original rows remain readable",
              status == 200 and isinstance(rows, list) and len(rows) > 0)

    # Historical driver fleet: seed one older active record without replaying
    # business triggers only in disposable local test DB, never hosted DB.
    legacy_name = "LEGACY-" + nonce
    psql(db, "BEGIN; SET LOCAL session_replication_role=replica; "
         "INSERT INTO public.drivers(company_id, name, full_name, is_active) "
         "VALUES('" + company + "','" + legacy_name + "','"
         + legacy_name + "',true); COMMIT;")
    check("historical driver over-cap remains untouched",
          count(db, "drivers", company, " AND is_active=true") == 6)
    denied_quota(
        write(api, owner_jwt, "drivers", company, "AFTER-LEGACY-" + nonce),
        "quota_drivers_reached",
        "historical above-cap company cannot increase occupied slots",
    )
    check("existing over-cap driver remains editable",
          edit(api, owner_jwt, "drivers", company,
               row(write(api, owner_jwt, "drivers", company,
                         "INACTIVE-LEGACY-" + nonce, active=False),
                   "inactive legacy fixture")["id"],
               {"notes": "Still accessible"})[0] == 200)

    status, snapshot = quota(api, owner_jwt, company)
    snapshot = snapshot[0] if isinstance(snapshot, list) else snapshot
    check("projection exposes all new counters and historical overcap",
          status == 200 and snapshot["usage"]["customers"] == 10
          and snapshot["usage"]["drivers"] == 6
          and snapshot["usage"]["routes"] == 10)
    print("Issue #355 disposable signed-JWT quota, tenant, role, race, "
          "reactivation, audit and historical tests PASS")


if __name__ == "__main__":
    main()
