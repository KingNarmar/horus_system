"""Issue #337: signed-JWT two-session finalize vs expense void verification.

DEVELOPMENT ONLY. Execute only against the exact Development Supabase host.
Requires isolated rows from issue_337_signed_jwt_fixture_setup_dev.sql.
No service-role keys, credentials, JWTs, or financial responses are printed.
This consumes one test fixture per run. Use --preflight before --execute.
"""

from __future__ import annotations

import getpass
import json
import os
import re
import sys
import threading
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass

DEV_HOST = "zwnfmszssxtfxkaofnhq.supabase.co"
UUID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
ALLOWED_CASES = frozenset({"race-a", "race-b"})
TIMEOUT_SECONDS = 20


def required_env(key: str) -> str:
    value = os.environ.get(key, "").strip()
    if not value:
        raise ValueError("Missing required Development configuration")
    return value


@dataclass(frozen=True)
class Reply:
    status: int
    data: object

    @property
    def ok(self) -> bool:
        return 200 <= self.status < 300

    @property
    def code(self) -> str | None:
        return str(self.data.get("code")) if isinstance(self.data, dict) and self.data.get("code") else None


@dataclass(frozen=True)
class Fixture:
    company: str
    expense: str
    settlement: str
    marker: str

    @classmethod
    def load(cls, test_case: str) -> "Fixture":
        suffix = "RACE_A" if test_case == "race-a" else "RACE_B"
        instance = cls(
            company=required_env("HORUS_337_COMPANY_A_ID"),
            expense=required_env(f"HORUS_337_{suffix}_EXPENSE_ID"),
            settlement=required_env(f"HORUS_337_{suffix}_SETTLEMENT_ID"),
            marker=required_env("HORUS_337_FIXTURE_MARKER"),
        )
        if not all(UUID.fullmatch(v) for v in (instance.company, instance.expense, instance.settlement)):
            raise ValueError("Untrusted Development fixture ID")
        if len(instance.marker) < 8:
            raise ValueError("Untrusted fixture marker")
        return instance


class DevelopmentGateway:
    def __init__(self) -> None:
        origin = urllib.parse.urlsplit(required_env("SUPABASE_URL"))
        if (
            origin.scheme != "https"
            or origin.hostname != DEV_HOST
            or origin.path not in ("", "/")
            or origin.query
            or origin.fragment
            or origin.username
            or origin.password
        ):
            raise ValueError("Only the fixed Development Supabase origin is allowed")
        self.base = f"https://{DEV_HOST}"
        self.key = required_env("SUPABASE_PUBLISHABLE_KEY")
        if not self.key.startswith("sb_publishable_"):
            raise ValueError("A Development publishable key is required")

    def request(
        self,
        method: str,
        path: str,
        *,
        jwt: str | None = None,
        params: dict[str, str] | None = None,
        data: dict[str, object] | None = None,
        prefer_representation: bool = False,
    ) -> Reply:
        if not path.startswith("/") or path.startswith("//") or "://" in path:
            raise ValueError("Unsupported request path")
        url = self.base + path
        if params:
            url += "?" + urllib.parse.urlencode(params)
        headers = {"apikey": self.key, "Accept": "application/json"}
        if jwt:
            headers["Authorization"] = f"Bearer {jwt}"
        if prefer_representation:
            headers["Prefer"] = "return=representation"
        payload = None
        if data is not None:
            headers["Content-Type"] = "application/json"
            payload = json.dumps(data).encode("utf-8")
        req = urllib.request.Request(url, data=payload, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as response:
                return Reply(response.status, json.loads(response.read().decode("utf-8")))
        except urllib.error.HTTPError as response:
            try:
                body = json.loads(response.read().decode("utf-8"))
            except (ValueError, UnicodeDecodeError):
                body = None
            return Reply(response.code, body)

    def login(self) -> tuple[str, str]:
        email = input("Development Owner email: ").strip()
        password = getpass.getpass("Password (hidden): ")
        reply = self.request(
            "POST", "/auth/v1/token?grant_type=password",
            data={"email": email, "password": password},
        )
        if not reply.ok or not isinstance(reply.data, dict):
            raise ValueError("Signed Development owner authentication refused")
        token = reply.data.get("access_token")
        user = reply.data.get("user")
        uid = user.get("id") if isinstance(user, dict) else None
        if not isinstance(token, str) or not isinstance(uid, str) or not UUID.fullmatch(uid):
            raise ValueError("Missing signed Development identity")
        return uid, token

    def rows(self, jwt: str, table: str, filters: dict[str, str]) -> list[dict[str, object]]:
        if table not in {
            "company_users", "expense_ledger_entries",
            "driver_settlements", "driver_settlement_items", "audit_logs",
        }:
            raise ValueError("Query outside allowed fixture tables")
        reply = self.request("GET", f"/rest/v1/{table}", jwt=jwt, params=filters)
        if not reply.ok or not isinstance(reply.data, list):
            raise ValueError("Unable to verify isolated Development fixture")
        if not all(isinstance(item, dict) for item in reply.data):
            raise ValueError("Unexpected Development response")
        return reply.data

    def one(self, jwt: str, table: str, company: str, record: str, select: str) -> dict[str, object]:
        rows = self.rows(jwt, table, {
            "select": select, "company_id": f"eq.{company}", "id": f"eq.{record}",
        })
        if len(rows) != 1:
            raise ValueError("Required Development fixture is unavailable")
        return rows[0]

    def audit_count(self, jwt: str, company: str, expense: str) -> int:
        return len(self.rows(jwt, "audit_logs", {
            "select": "id", "company_id": f"eq.{company}",
            "entity_id": f"eq.{expense}", "action": "eq.voided",
        }))


def preflight(gateway: DevelopmentGateway, jwt: str, uid: str, fixture: Fixture) -> None:
    membership = gateway.rows(jwt, "company_users", {
        "select": "company_id,user_id,role,is_active", "user_id": f"eq.{uid}",
    })
    if not any(
        r.get("company_id") == fixture.company
        and r.get("role") == "owner"
        and r.get("is_active") is True
        for r in membership
    ):
        raise ValueError("A signed Owner of the exact test company is required")

    expense = gateway.one(
        jwt, "expense_ledger_entries", fixture.company, fixture.expense,
        "id,company_id,description,origin_kind,trip_id,funding_source,is_voided",
    )
    settlement = gateway.one(
        jwt, "driver_settlements", fixture.company, fixture.settlement,
        "id,company_id,status,notes",
    )
    if (
        fixture.marker not in str(expense.get("description"))
        or fixture.marker not in str(settlement.get("notes"))
        or expense.get("is_voided") is not False
        or expense.get("origin_kind") != "manual"
        or not expense.get("trip_id")
        or expense.get("funding_source") not in ("driver_cash", "driver_advance")
        or settlement.get("status") != "draft"
    ):
        raise ValueError("Fixture is not an untouched marked Development race")

    items = gateway.rows(jwt, "driver_settlement_items", {
        "select": "source_id", "company_id": f"eq.{fixture.company}",
        "settlement_id": f"eq.{fixture.settlement}",
        "source_type": "eq.trip_expense",
    })
    if len(items) != 1 or items[0].get("source_id") != fixture.expense:
        raise ValueError("Draft does not capture the exact marked expense")
    if gateway.audit_count(jwt, fixture.company, fixture.expense) != 0:
        raise ValueError("Fixture has a pre-existing expense void audit")


def execute_race(gateway: DevelopmentGateway, jwt: str, fixture: Fixture) -> None:
    barrier = threading.Barrier(2, timeout=TIMEOUT_SECONDS)

    def void() -> Reply:
        barrier.wait()
        return gateway.request(
            "POST", "/rest/v1/rpc/void_expense_ledger_entry", jwt=jwt,
            data={"p_company_id": fixture.company, "p_expense_id": fixture.expense,
                  "p_reason": fixture.marker},
        )

    def finalize() -> Reply:
        barrier.wait()
        return gateway.request(
            "PATCH", "/rest/v1/driver_settlements", jwt=jwt,
            params={"company_id": f"eq.{fixture.company}", "id": f"eq.{fixture.settlement}"},
            data={"status": "finalized"}, prefer_representation=True,
        )

    with ThreadPoolExecutor(max_workers=2) as pool:
        void_future = pool.submit(void)
        finalize_future = pool.submit(finalize)
        void_result = void_future.result()
        finalize_result = finalize_future.result()

    expense = gateway.one(
        jwt, "expense_ledger_entries", fixture.company, fixture.expense,
        "id,company_id,is_voided",
    )
    settlement = gateway.one(
        jwt, "driver_settlements", fixture.company, fixture.settlement,
        "id,company_id,status",
    )
    audits = gateway.audit_count(jwt, fixture.company, fixture.expense)

    if void_result.ok and not finalize_result.ok:
        valid = (
            finalize_result.code == "P2812"
            and expense.get("is_voided") is True
            and settlement.get("status") == "draft"
            and audits == 1
        )
    elif finalize_result.ok and not void_result.ok:
        valid = (
            void_result.code == "P2811"
            and expense.get("is_voided") is False
            and settlement.get("status") == "finalized"
            and audits == 0
        )
    else:
        valid = False
    if not valid:
        raise ValueError("Concurrent financial integrity assertion failed")
    print("PASS  exactly one mutation committed; settlement/ledger/audit invariant intact")


def main() -> int:
    try:
        if len(sys.argv) != 3 or sys.argv[1] not in ("--preflight", "--execute"):
            raise ValueError("Use --preflight/--execute --case=race-a or race-b")
        if not sys.argv[2].startswith("--case="):
            raise ValueError("Fixture case required")
        test_case = sys.argv[2][len("--case="):]
        if test_case not in ALLOWED_CASES:
            raise ValueError("Unknown fixture case")

        fixture = Fixture.load(test_case)
        gateway = DevelopmentGateway()
        if sys.argv[1] == "--execute":
            challenge = input("Type EXECUTE + fixture marker + case: ").strip()
            if challenge != f"EXECUTE {fixture.marker} {test_case}":
                raise ValueError("Explicit Development execution approval is required")
        uid, jwt = gateway.login()
        preflight(gateway, jwt, uid, fixture)
        if sys.argv[1] == "--preflight":
            print("PASS  signed Owner, tenant, draft, expense and source fixture")
        else:
            execute_race(gateway, jwt, fixture)
        return 0
    except (Exception, KeyboardInterrupt):
        print("BLOCKED — Development precondition or race invariant failed (details suppressed).", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
