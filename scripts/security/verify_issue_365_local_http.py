"""Local-only real GoTrue JWT / REST / RPC / concurrency test for #365.

Run only against a disposable Supabase CLI local stack. No hosted credentials.
"""
import concurrent.futures
import json
import secrets
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid


def shell(*cmd, input_text=None):
    p = subprocess.run(cmd, input=input_text, text=True, capture_output=True, check=True)
    return p.stdout.strip()


def local_stack():
    info = json.loads(shell("npx", "--yes", "supabase@3.0.0", "status", "-o", "json"))
    url = info.get("API_URL") or info.get("api_url")
    public = info.get("PUBLISHABLE_KEY") or info.get("ANON_KEY")
    admin = info.get("SERVICE_ROLE_KEY") or info.get("SECRET_KEY")
    if not all(isinstance(x, str) and x for x in (url, public, admin)):
        raise RuntimeError("Local Supabase CLI key configuration missing")
    origin = urllib.parse.urlparse(url)
    if origin.scheme != "http" or origin.hostname not in ("localhost", "127.0.0.1"):
        raise RuntimeError("Refusing non-local Supabase endpoint")
    containers = shell(
        "docker", "ps", "--filter", "name=supabase_db_", "--format", "{{.Names}}"
    ).splitlines()
    if len(containers) != 1 or not containers[0].startswith("supabase_db_"):
        raise RuntimeError("Expected exactly one disposable local DB")
    return url, public, admin, containers[0]


def psql(db, stmt):
    return shell("docker", "exec", "-i", db, "psql", "-U", "postgres",
                 "-d", "postgres", "-X", "-q", "-A", "-t", "-v", "ON_ERROR_STOP=1",
                 input_text=stmt).splitlines()[0]


def uid(v):
    return str(uuid.UUID(str(v)))


def check(label, condition):
    if not condition:
        raise AssertionError(label)
    print("PASS", label, flush=True)


class LocalApi:
    def __init__(self, url, public_key, admin_key):
        self.url, self.public, self.admin = url, public_key, admin_key

    def call(self, method, path, token=None, payload=None, admin=False, query=None):
        if not path.startswith("/") or path.startswith("//"):
            raise RuntimeError("Only local relative API calls permitted")
        url = self.url + path
        if query:
            url += ("&" if "?" in url else "?") + urllib.parse.urlencode(query)
        headers = {
            "apikey": self.admin if admin else self.public,
            "Accept": "application/json",
            "Prefer": "return=representation",
        }
        if admin:
            headers["Authorization"] = "Bearer " + self.admin
        if token:
            headers["Authorization"] = "Bearer " + token
        if payload is not None:
            headers["Content-Type"] = "application/json"
        req = urllib.request.Request(
            url, json.dumps(payload).encode() if payload is not None else None,
            headers=headers, method=method
        )
        try:
            with urllib.request.urlopen(req, timeout=25) as res:
                status, data = res.status, res.read().decode()
        except urllib.error.HTTPError as err:
            status, data = err.code, err.read().decode()
        try:
            return status, json.loads(data) if data else None
        except json.JSONDecodeError:
            return status, None

    def create_session(self, role, nonce):
        email = "horus365-" + role + "-" + nonce + "@example.test"
        pwd = secrets.token_urlsafe(24)
        status, body = self.call(
            "POST", "/auth/v1/admin/users", admin=True,
            payload={"email": email, "password": pwd, "email_confirm": True}
        )
        person = body.get("user", body) if isinstance(body, dict) else {}
        if status not in (200, 201) or not person.get("id"):
            raise RuntimeError("Local test user creation failed (HTTP %s)" % status)
        user_id = uid(person["id"])
        status, session = self.call(
            "POST", "/auth/v1/token?grant_type=password",
            payload={"email": email, "password": pwd}
        )
        if status != 200 or not isinstance(session, dict) or not session.get("access_token"):
            raise RuntimeError("Local test JWT login failed (HTTP %s)" % status)
        jwt = session["access_token"]
        status, verified = self.call("GET", "/auth/v1/user", token=jwt)
        if status != 200 or not isinstance(verified, dict) or verified.get("id") != user_id:
            raise RuntimeError("JWT not accepted by local Auth server")
        return user_id, jwt


def rpc(api, token, name, args):
    return api.call("POST", "/rest/v1/rpc/" + name, token=token, payload=args)


def route_projection(api, token, company, route):
    status, data = rpc(api, token, "get_authorized_route_records", {
        "p_company_id": company, "p_route_id": route, "p_active_only": False
    })
    if status != 200:
        raise RuntimeError("Authorized Route projection unavailable")
    rows = data if isinstance(data, list) else [data]
    if len(rows) != 1 or not isinstance(rows[0], dict):
        raise RuntimeError("Route projection did not return a record")
    return rows[0]


def rate_rpc(api, token, company, route, value, expected):
    return rpc(api, token, "set_route_default_freight_rate_atomic", {
        "p_company_id": company, "p_route_id": route,
        "p_default_freight_rate": value, "p_expected_updated_at": expected
    })


def main():
    url, public, admin, db = local_stack()
    api = LocalApi(url, public, admin)
    nonce = secrets.token_hex(6)
    roles = ("owner", "admin", "accountant", "operations", "viewer", "driver", "foreign_owner")
    accounts = {role: api.create_session(role, nonce) for role in roles}
    owner_id = accounts["owner"][0]
    foreign_id = accounts["foreign_owner"][0]
    a = uid(psql(db, "INSERT INTO public.companies(name,base_currency_code,"
                  "base_currency_fraction_digits,created_by) VALUES"
                  "('HORUS365-LOCAL-" + nonce + "-A','AED',2,'" + owner_id +
                  "') RETURNING id;"))
    b = uid(psql(db, "INSERT INTO public.companies(name,base_currency_code,"
                  "base_currency_fraction_digits,created_by) VALUES"
                  "('HORUS365-LOCAL-" + nonce + "-B','CLF',4,'" + foreign_id +
                  "') RETURNING id;"))
    for role in roles:
        company = b if role == "foreign_owner" else a
        userid = accounts[role][0]
        psql(db, "INSERT INTO public.company_users(company_id,user_id,role,is_active,created_by)"
                 " VALUES('" + company + "','" + userid + "','" +
                 ("owner" if role == "foreign_owner" else role) +
                 "',true,'" + userid + "');")
    check("two local companies; six real JWT role logins", True)

    def create_route(token, company, amount, label):
        return api.call("POST", "/rest/v1/routes", token=token, query={"select": "id"},
                        payload={"company_id": company, "loading_location": "TEST-LOAD",
                                 "unloading_location": "TEST-UNLOAD",
                                 "default_freight_price": amount, "notes": label})

    status, _ = create_route(accounts["owner"][1], a, 10.5, "HORUS365-LOCAL-A")
    check("signed owner Route INSERT", status == 201)
    route = uid(psql(db, "SELECT id FROM public.routes WHERE company_id='" +
                         a + "' AND notes='HORUS365-LOCAL-A';"))
    status, _ = create_route(accounts["foreign_owner"][1], b, 10.1234, "HORUS365-LOCAL-B")
    check("four-decimal valid Route INSERT", status == 201)
    status, error = create_route(accounts["foreign_owner"][1], b, 64.12345,
                                 "HORUS365-LOCAL-INVALID")
    check("five decimals rejected without rounding",
          status >= 400 and isinstance(error, dict) and error.get("code") == "P3441")
    status, error = create_route(accounts["owner"][1], a, 44.123,
                                 "HORUS365-LOCAL-INVALID")
    check("two-decimal company rejects three decimals",
          status >= 400 and isinstance(error, dict) and error.get("code") == "P3441")

    for role in roles[:-1]:
        token = accounts[role][1]
        status, err = api.call("GET", "/rest/v1/routes", token=token,
                               query={"select": "default_freight_price", "id": "eq." + route})
        check(role + " financial SELECT denied",
              status in (401, 403) and isinstance(err, dict) and err.get("code") == "42501")
        status, err = api.call(
            "PATCH", "/rest/v1/routes", token=token,
            query={"company_id": "eq." + a, "id": "eq." + route, "select": "id"},
            payload={"default_freight_price": 22.12}
        )
        check(role + " direct financial PATCH denied",
              status in (401, 403) and isinstance(err, dict) and err.get("code") == "42501")
        status, rows = api.call("GET", "/rest/v1/routes", token=token,
                                query={"select": "id", "company_id": "eq." + b})
        check(role + " foreign-tenant Route isolation", status == 200 and rows == [])
        status, rows = api.call(
            "PATCH", "/rest/v1/routes", token=token,
            query={"company_id": "eq." + a, "id": "eq." + route, "select": "id"},
            payload={"notes": "HORUS365-ROLE-" + role}
        )
        allowed = role in ("owner", "admin", "operations")
        check(role + " operational PATCH permission",
              status in (200, 204) and (bool(rows) if allowed else not rows))

    for role in ("operations", "viewer", "driver"):
        status, err = rate_rpc(
            api, accounts[role][1], a, route, "12.12", "2000-01-01T00:00:00Z"
        )
        check(role + " finance RPC denied",
              status >= 400 and isinstance(err, dict) and err.get("code") == "P3431")

    for role in ("owner", "admin", "accountant"):
        token = accounts[role][1]
        current = route_projection(api, token, a, route)
        status, body = rate_rpc(api, token, a, route, "12.12", current["updated_at"])
        check(role + " authorized rate RPC",
              status == 200 and isinstance(body, dict) and
              float(body["default_freight_price"]) == 12.12)

    ts = route_projection(api, accounts["owner"][1], a, route)["updated_at"]
    count_sql = ("SELECT count(*) FROM public.audit_logs WHERE company_id='" + a +
                 "' AND entity_id='" + route + "' AND module='routes' AND action='updated';")
    old_count = int(psql(db, count_sql))
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        futures = [
            pool.submit(rate_rpc, api, accounts[role][1], a, route, amount, ts)
            for role, amount in (("owner", "13.12"), ("admin", "14.12"))
        ]
        replies = [f.result() for f in futures]
    winners = [body for status, body in replies if status == 200]
    losers = [body for status, body in replies if status >= 400]
    check("two simultaneous JWT requests yield one successful write",
          len(winners) == 1 and len(losers) == 1)
    check("losing request rejected with P3440",
          isinstance(losers[0], dict) and losers[0].get("code") == "P3440")
    latest = route_projection(api, accounts["owner"][1], a, route)
    check("winning rate is preserved",
          float(latest["default_freight_price"]) ==
          float(winners[0]["default_freight_price"]))
    check("exactly one audit row for racing writes", int(psql(db, count_sql)) == old_count + 1)
    print("SUCCESS: #365 disposable signed-JWT HTTP and concurrent RPC suite", flush=True)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("FAIL: #365 local HTTP verification: " + type(error).__name__ +
              ": " + str(error), file=sys.stderr)
        raise SystemExit(1)
