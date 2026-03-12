#!/usr/bin/env python3
"""Store a JWT from identity login callback for local E2E reuse."""

from __future__ import annotations

import base64
import json
import sys
import textwrap
import webbrowser
from datetime import datetime, timezone
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
TOKEN_CACHE_PATH = SCRIPT_DIR / ".e2e_identity_token.json"
IDENTITY_TEST_PAGE = "http://localhost:8082/test"
IDENTITY_TEST_CLIENT = "http://localhost:3000"


def _pad_base64(data: str) -> str:
    return data + "=" * (-len(data) % 4)


def decode_jwt_payload(token: str) -> dict[str, object]:
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("Token must have 3 JWT parts.")
    payload_raw = base64.urlsafe_b64decode(_pad_base64(parts[1]))
    payload = json.loads(payload_raw.decode("utf-8"))
    if not isinstance(payload, dict):
        raise ValueError("JWT payload is not a JSON object.")
    return payload


def extract_token(raw_text: str) -> tuple[str, str]:
    text = raw_text.strip()
    if not text:
        raise ValueError("No input provided.")

    if text.count(".") == 2 and "{" not in text:
        return text, "raw_jwt"

    try:
        payload = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError("Input is neither raw JWT nor JSON callback body.") from exc

    if not isinstance(payload, dict):
        raise ValueError("JSON input must be an object.")

    token = payload.get("token")
    if isinstance(token, str) and token:
        return token, "json.token"

    data = payload.get("data")
    if isinstance(data, dict):
        token = data.get("token")
        if isinstance(token, str) and token:
            return token, "json.data.token"

    raise ValueError("Could not find token in JSON input.")


def format_expiry(payload: dict[str, object]) -> tuple[int | None, str]:
    exp = payload.get("exp")
    if not isinstance(exp, int):
        return None, "unknown"
    dt = datetime.fromtimestamp(exp, tz=timezone.utc)
    return exp, dt.isoformat()


def save_token(token: str, source: str) -> None:
    payload = decode_jwt_payload(token)
    exp, exp_iso = format_expiry(payload)
    body = {
        "token": token,
        "source": source,
        "saved_at": datetime.now(timezone.utc).isoformat(),
        "expires_at_unix": exp,
        "expires_at": exp_iso,
        "claims": {
            "sub": payload.get("sub"),
            "email": payload.get("email") or payload.get("username"),
            "role": payload.get("role"),
            "iss": payload.get("iss"),
            "aud": payload.get("aud"),
        },
    }
    TOKEN_CACHE_PATH.write_text(
        json.dumps(body, ensure_ascii=True, indent=2),
        encoding="utf-8",
    )


def main() -> int:
    print("Identity token helper")
    print(f"Token cache: {TOKEN_CACHE_PATH}")
    print("")
    print("Login pages:")
    print(f"- Identity dev page: {IDENTITY_TEST_PAGE}")
    print(f"- Standalone test client: {IDENTITY_TEST_CLIENT}")
    print("")

    try:
        webbrowser.open(IDENTITY_TEST_PAGE, new=2)
        print("Opened identity test page in your browser.")
    except Exception:
        print("Could not open browser automatically.")

    print("")
    print(
        textwrap.dedent(
            """
            Paste one of these, then press Enter and Ctrl-D / Ctrl-Z:
            - raw JWT token
            - full JSON callback body from identity
            """
        ).strip()
    )

    raw_input_text = sys.stdin.read().strip()
    if not raw_input_text:
        try:
            raw_input_text = input("Token or JSON body: ").strip()
        except EOFError:
            raw_input_text = ""

    try:
        token, source = extract_token(raw_input_text)
        payload = decode_jwt_payload(token)
        _, exp_iso = format_expiry(payload)
        save_token(token, source)
    except Exception as exc:  # pylint: disable=broad-except
        print(f"Failed to store token: {exc}", file=sys.stderr)
        return 1

    print("")
    print("Token saved successfully.")
    print(f"- source: {source}")
    print(f"- subject: {payload.get('sub')}")
    print(f"- role: {payload.get('role')}")
    print(f"- issuer: {payload.get('iss')}")
    print(f"- expires_at: {exp_iso}")
    print("")
    print("Next step:")
    print("python test/e2e_identity_project_ingest.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
