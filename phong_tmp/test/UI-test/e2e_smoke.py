#!/usr/bin/env python3
"""Smoke E2E checks for UI-prod_test against production gateways."""

from __future__ import annotations

import unittest
from urllib.parse import parse_qs, urlparse

from e2e_common import BASE_API_URL, BASE_UI_URL, LOCAL_ORIGIN, build_session, run_ui_server


class UISmokeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._server = run_ui_server()
        cls._server.__enter__()
        cls.session = build_session()

    @classmethod
    def tearDownClass(cls) -> None:
        cls._server.__exit__(None, None, None)

    def test_root_page_serves_production_console_markup(self) -> None:
        response = self.session.get(f"{BASE_UI_URL}/", timeout=10)
        self.assertEqual(response.status_code, 200)
        self.assertIn("SMAP Production API Console", response.text)
        self.assertIn('id="auth-action"', response.text)
        self.assertIn('id="runtime-identity"', response.text)
        self.assertIn('id="runtime-swagger"', response.text)

    def test_module_assets_are_served(self) -> None:
        for path in ["/app.js", "/js/config.js", "/js/api.js", "/styles.css"]:
            with self.subTest(path=path):
                response = self.session.get(f"{BASE_UI_URL}{path}", timeout=10)
                self.assertEqual(response.status_code, 200)
                self.assertTrue(response.text)


class ProductionGatewaySmokeTests(unittest.TestCase):
    def setUp(self) -> None:
        self.session = build_session()

    def test_identity_me_requires_auth_but_allows_local_origin(self) -> None:
        response = self.session.get(
            f"{BASE_API_URL}/identity/api/v1/authentication/me",
            headers={"Origin": LOCAL_ORIGIN},
            timeout=15,
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.headers.get("Access-Control-Allow-Origin"), LOCAL_ORIGIN)
        self.assertEqual(response.json()["error"]["code"], "MISSING_TOKEN")

    def test_project_campaigns_requires_auth_but_allows_local_origin(self) -> None:
        response = self.session.get(
            f"{BASE_API_URL}/project/api/v1/campaigns",
            headers={"Origin": LOCAL_ORIGIN},
            timeout=15,
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.headers.get("Access-Control-Allow-Origin"), LOCAL_ORIGIN)
        self.assertEqual(response.json()["error"]["code"], "MISSING_TOKEN")

    def test_ingest_datasources_requires_auth_but_allows_local_origin(self) -> None:
        response = self.session.get(
            f"{BASE_API_URL}/ingest/api/v1/datasources",
            headers={"Origin": LOCAL_ORIGIN},
            timeout=15,
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.headers.get("Access-Control-Allow-Origin"), LOCAL_ORIGIN)
        self.assertEqual(response.json()["error"]["code"], "MISSING_TOKEN")

    def test_login_redirect_accepts_localhost_return_url(self) -> None:
        redirect_url = f"{BASE_UI_URL}/#/campaigns"
        response = self.session.get(
            f"{BASE_API_URL}/identity/api/v1/authentication/login",
            headers={"Origin": LOCAL_ORIGIN},
            params={"redirect": redirect_url},
            allow_redirects=False,
            timeout=15,
        )
        self.assertEqual(response.status_code, 307)
        self.assertIn("oauth_state", response.cookies)

        location = response.headers["Location"]
        parsed = urlparse(location)
        self.assertEqual(parsed.netloc, "accounts.google.com")

        query = parse_qs(parsed.query)
        self.assertEqual(
            query["redirect_uri"][0],
            "https://smap-api.tantai.dev/identity/api/v1/authentication/callback",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
