#!/usr/bin/env python3
"""Serve the SMAP UI test page on localhost:3005."""

from __future__ import annotations

import http.server
import socketserver
from pathlib import Path


PORT = 3005
ROOT = Path(__file__).resolve().parent


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print("---------------------------------------------------------")
        print(f"   UI Test server running at http://localhost:{PORT}")
        print(f"   Serving: {ROOT}")
        print("---------------------------------------------------------")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
