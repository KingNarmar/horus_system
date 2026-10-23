"""Offline regression tests for Issue #337 signed-JWT concurrency preflight."""

import os
import unittest
from unittest.mock import patch

import verify_issue_337_concurrent_void_finalize as race_probe


class Issue337PreflightTests(unittest.TestCase):
    def test_accepts_canonical_fixture_uuids(self):
        for identifier in (
            "041a7fc8-3593-41f2-b00f-99643277b18f",
            "f8273701-cc58-4a49-9b5a-05c89529301a",
            "d09d124c-9413-453a-8032-3da143586f9b",
        ):
            with self.subTest(identifier=identifier):
                self.assertIsNotNone(race_probe.UUID.fullmatch(identifier))

    def test_rejects_malformed_and_four_group_uuids(self):
        for identifier in (
            "",
            "00000000-0000-0000-000000000001",
            "00000000-0000-0000-0000-000000000001 ",
            "00000000-0000-0000-0000-00000000000Z",
        ):
            with self.subTest(identifier=identifier):
                self.assertIsNone(race_probe.UUID.fullmatch(identifier))

    def test_loads_both_isolated_race_fixture_variants_without_network(self):
        values = {
            "HORUS_337_COMPANY_A_ID": "041a7fc8-3593-41f2-b00f-99643277b18f",
            "HORUS_337_RACE_A_EXPENSE_ID": "f8273701-cc58-4a49-9b5a-05c89529301a",
            "HORUS_337_RACE_A_SETTLEMENT_ID": "d09d124c-9413-453a-8032-3da143586f9b",
            "HORUS_337_RACE_B_EXPENSE_ID": "477d783d-33dd-4c4b-b1f5-5e0dff72e312",
            "HORUS_337_RACE_B_SETTLEMENT_ID": "aec4e242-48ac-425e-8895-d68b2cb99e4f",
            "HORUS_337_FIXTURE_MARKER": "issue337-2216cba43ad646",
        }
        with patch.dict(os.environ, values, clear=True):
            a = race_probe.Fixture.load("race-a")
            b = race_probe.Fixture.load("race-b")
            self.assertNotEqual(a.expense, b.expense)
            self.assertNotEqual(a.settlement, b.settlement)
            self.assertEqual(a.company, b.company)

    def test_refuses_invalid_or_missing_fixture_ids(self):
        values = {
            "HORUS_337_COMPANY_A_ID": "041a7fc8-3593-41f2-b00f-99643277b18f",
            "HORUS_337_RACE_A_EXPENSE_ID": "00000000-0000-0000-000000000001",
            "HORUS_337_RACE_A_SETTLEMENT_ID": "d09d124c-9413-453a-8032-3da143586f9b",
            "HORUS_337_FIXTURE_MARKER": "issue337-2216cba43ad646",
        }
        with patch.dict(os.environ, values, clear=True):
            with self.assertRaises(ValueError):
                race_probe.Fixture.load("race-a")


if __name__ == "__main__":
    unittest.main()
