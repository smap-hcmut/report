#!/usr/bin/env python3
"""Authenticated production checks for UI-prod_test.

Requires:
  SMAP_AUTH_COOKIE=<value of smap_auth_token>
"""

from __future__ import annotations

import unittest

from e2e_common import BASE_API_URL, LOCAL_ORIGIN, build_session, require_auth_cookie


class AuthenticatedProductionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        try:
            auth_cookie = require_auth_cookie()
        except RuntimeError as exc:
            raise unittest.SkipTest(str(exc)) from exc

        cls.session = build_session(auth_cookie)

    def test_identity_me_returns_current_user(self) -> None:
        response = self.session.get(
            f"{BASE_API_URL}/identity/api/v1/authentication/me",
            headers={"Origin": LOCAL_ORIGIN},
            timeout=15,
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload.get("error_code"), 0)
        self.assertIn("data", payload)
        self.assertIn("email", payload["data"])

    def test_project_campaigns_lists_for_authenticated_user(self) -> None:
        response = self.session.get(
            f"{BASE_API_URL}/project/api/v1/campaigns",
            headers={"Origin": LOCAL_ORIGIN},
            params={"page": 1, "limit": 5},
            timeout=15,
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload.get("error_code"), 0)
        self.assertIn("data", payload)
        self.assertIn("campaigns", payload["data"])

    def test_ingest_datasources_lists_for_authenticated_user(self) -> None:
        response = self.session.get(
            f"{BASE_API_URL}/ingest/api/v1/datasources",
            headers={"Origin": LOCAL_ORIGIN},
            params={"page": 1, "limit": 5},
            timeout=15,
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload.get("error_code"), 0)
        self.assertIn("data", payload)
        self.assertIn("data_sources", payload["data"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
