#!/usr/bin/env python3
"""Shared helpers for UI-prod_test E2E smoke checks."""

from __future__ import annotations

import os
import socket
import subprocess
import sys
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

import requests


ROOT = Path(__file__).resolve().parent
BASE_UI_URL = "http://127.0.0.1:3005"
BASE_API_URL = "https://smap-api.tantai.dev"
LOCAL_ORIGIN = BASE_UI_URL
AUTH_COOKIE_NAME = "smap_auth_token"


def wait_for_port(host: str, port: int, timeout_s: float = 15.0) -> None:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
            sock.settimeout(0.5)
            if sock.connect_ex((host, port)) == 0:
                return
        time.sleep(0.2)
    raise TimeoutError(f"Timed out waiting for {host}:{port}")


@contextmanager
def run_ui_server() -> Iterator[subprocess.Popen[str]]:
    proc = subprocess.Popen(
        [sys.executable, "test.py"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    try:
        wait_for_port("127.0.0.1", 3005)
        yield proc
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)
        if proc.stdout:
            proc.stdout.close()


def build_session(auth_cookie: str | None = None) -> requests.Session:
    session = requests.Session()
    if auth_cookie:
        session.cookies.set(AUTH_COOKIE_NAME, auth_cookie, domain="smap-api.tantai.dev", path="/")
    return session


def require_auth_cookie() -> str:
    value = os.getenv("SMAP_AUTH_COOKIE", "").strip()
    if not value:
        raise RuntimeError("SMAP_AUTH_COOKIE is not set")
    return value
