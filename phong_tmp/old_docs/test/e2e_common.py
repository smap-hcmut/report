#!/usr/bin/env python3
"""Shared helpers for local E2E smoke and negative suites."""

from __future__ import annotations

import base64
import hashlib
import hmac
import json
import os
import time
import uuid
from pathlib import Path
from typing import Any, Iterable
from urllib import error as urllib_error
from urllib import request as urllib_request


SCRIPT_DIR = Path(__file__).resolve().parent
TOKEN_CACHE_PATH = SCRIPT_DIR / ".e2e_identity_token.json"
ARTIFACTS_DIR = SCRIPT_DIR / "artifacts"

DEFAULT_IDENTITY_BASE_URL = os.environ.get("IDENTITY_BASE_URL", "http://localhost:8082")
DEFAULT_PROJECT_BASE_URL = os.environ.get("PROJECT_BASE_URL", "http://localhost:8081")
DEFAULT_INGEST_BASE_URL = os.environ.get("INGEST_BASE_URL", "http://localhost:8080")
DEFAULT_JWT_SECRET_KEY = os.environ.get(
    "JWT_SECRET_KEY",
    "smap-secret-key-at-least-32-chars-long",
)
REQUEST_TIMEOUT_SECONDS = 30


class E2EError(RuntimeError):
    """Raised when an E2E step fails."""


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def _b64url_decode(data: str) -> bytes:
    padded = data + "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(padded.encode("ascii"))


def decode_jwt_payload(token: str) -> dict[str, Any]:
    parts = token.split(".")
    if len(parts) != 3:
        raise E2EError("JWT token must have exactly 3 parts.")
    try:
        payload = json.loads(_b64url_decode(parts[1]).decode("utf-8"))
    except Exception as exc:  # pylint: disable=broad-except
        raise E2EError(f"Failed to decode JWT payload: {exc}") from exc
    if not isinstance(payload, dict):
        raise E2EError("JWT payload is not an object.")
    return payload


def create_hs256_token(claims: dict[str, Any], secret_key: str) -> str:
    header = {"alg": "HS256", "typ": "JWT"}
    header_b64 = _b64url_encode(
        json.dumps(header, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    )
    payload_b64 = _b64url_encode(
        json.dumps(claims, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    )
    signing_input = f"{header_b64}.{payload_b64}".encode("ascii")
    signature = hmac.new(
        secret_key.encode("utf-8"), signing_input, hashlib.sha256
    ).digest()
    return f"{header_b64}.{payload_b64}.{_b64url_encode(signature)}"


def load_token() -> str:
    if not TOKEN_CACHE_PATH.exists():
        raise E2EError(
            "Missing token cache. Run 'python test/login_identity_token_helper.py' first."
        )
    payload = json.loads(TOKEN_CACHE_PATH.read_text(encoding="utf-8"))
    token = payload.get("token")
    if not isinstance(token, str) or not token:
        raise E2EError(
            f"Token cache is invalid: {TOKEN_CACHE_PATH}. Refresh it with the helper script."
        )
    return token


def build_negative_tokens(
    real_token: str, secret_key: str = DEFAULT_JWT_SECRET_KEY
) -> dict[str, str]:
    real_claims = decode_jwt_payload(real_token)
    now = int(time.time())
    expired_claims = dict(real_claims)
    expired_claims["exp"] = now - 3600
    expired_claims["iat"] = now - 7200
    expired_claims["jti"] = str(uuid.uuid4())

    invalid_signature = create_hs256_token(real_claims, secret_key + "-mismatch")

    return {
        "valid": real_token,
        "missing": "",
        "malformed": "not-a-jwt",
        "invalid_signature": invalid_signature,
        "expired": create_hs256_token(expired_claims, secret_key),
    }


def extract_data(body: Any) -> dict[str, Any]:
    if not isinstance(body, dict):
        raise E2EError(f"Expected JSON object response, got: {body!r}")
    data = body.get("data")
    if not isinstance(data, dict):
        raise E2EError(f"Missing 'data' object in response: {body!r}")
    return data


def format_body(body: Any) -> str:
    try:
        return json.dumps(body, ensure_ascii=True, sort_keys=True)
    except TypeError:
        return repr(body)


def effective_status(status: int, body: Any) -> int:
    if status == 200 and isinstance(body, dict):
        error_code = body.get("error_code")
        if isinstance(error_code, int) and error_code in {400, 401, 403, 404, 409, 422, 500}:
            return error_code
    return status


def make_name(prefix: str) -> str:
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    suffix = uuid.uuid4().hex[:6]
    return f"E2E_{timestamp}_{prefix}_{suffix}"


def http_get_json(url: str) -> tuple[int, Any]:
    req = urllib_request.Request(
        url=url,
        headers={"Accept": "application/json"},
        method="GET",
    )
    try:
        with urllib_request.urlopen(req, timeout=REQUEST_TIMEOUT_SECONDS) as response:
            status = response.getcode()
            raw_body = response.read().decode("utf-8")
    except urllib_error.HTTPError as exc:
        status = exc.code
        raw_body = exc.read().decode("utf-8", errors="replace")
    except urllib_error.URLError as exc:
        return 0, {"request_error": str(exc)}

    try:
        return status, json.loads(raw_body)
    except ValueError:
        return status, raw_body


def check_health(name: str, base_url: str) -> str | None:
    status, body = http_get_json(f"{base_url.rstrip('/')}/health")
    if status != 200:
        return f"{name} health check failed: status={status}, body={format_body(body)}"
    print(f"  OK  {name} /health -> {format_body(body)}")
    return None


def ensure_services_healthy(identity_base: str, project_base: str, ingest_base: str) -> None:
    errors = [
        error
        for error in (
            check_health("identity", identity_base),
            check_health("project", project_base),
            check_health("ingest", ingest_base),
        )
        if error
    ]
    if errors:
        raise E2EError("; ".join(errors))


def normalize_expected_status(expected_status: int | Iterable[int]) -> tuple[int, ...]:
    if isinstance(expected_status, int):
        return (expected_status,)
    return tuple(int(item) for item in expected_status)


class HttpClient:
    def __init__(self, token: str | None = None):
        self.token = token

    def request(
        self,
        *,
        step: str,
        method: str,
        url: str,
        json_body: dict[str, Any] | None = None,
        expected_status: int | Iterable[int] = 200,
        fatal: bool = True,
        extra_headers: dict[str, str] | None = None,
    ) -> tuple[int, Any]:
        data: bytes | None = None
        headers = {"Accept": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        if extra_headers:
            headers.update(extra_headers)
        if json_body is not None:
            data = json.dumps(json_body, ensure_ascii=True).encode("utf-8")
            headers["Content-Type"] = "application/json"

        req = urllib_request.Request(
            url=url,
            data=data,
            headers=headers,
            method=method.upper(),
        )

        try:
            with urllib_request.urlopen(req, timeout=REQUEST_TIMEOUT_SECONDS) as response:
                status = response.getcode()
                raw_body = response.read().decode("utf-8")
        except urllib_error.HTTPError as exc:
            status = exc.code
            raw_body = exc.read().decode("utf-8", errors="replace")
        except urllib_error.URLError as exc:
            if fatal:
                raise E2EError(f"{step}: request failed: {exc}") from exc
            return 0, {"request_error": str(exc)}

        try:
            body: Any = json.loads(raw_body)
        except ValueError:
            body = raw_body

        expected = normalize_expected_status(expected_status)
        if status not in expected and fatal:
            raise E2EError(
                f"{step}: expected {expected}, got {status}, body={format_body(body)}"
            )
        return status, body


class ArtifactStore:
    def __init__(self, suite_name: str):
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        self.base_dir = ARTIFACTS_DIR / f"{timestamp}_{suite_name}"
        self.created = False

    def write_failure(self, case_id: str, payload: dict[str, Any]) -> Path:
        if not self.created:
            self.base_dir.mkdir(parents=True, exist_ok=True)
            self.created = True
        path = self.base_dir / f"{case_id}.json"
        path.write_text(
            json.dumps(payload, ensure_ascii=True, indent=2, sort_keys=True),
            encoding="utf-8",
        )
        return path
