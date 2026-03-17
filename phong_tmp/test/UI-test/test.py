#!/usr/bin/env python3
"""Serve the SMAP UI test page on localhost:3005."""

from __future__ import annotations

import http.server
import mimetypes
import socketserver
from pathlib import Path


PORT = 3005
ROOT = Path(__file__).resolve().parent


class Handler(http.server.SimpleHTTPRequestHandler):
    # Windows mime registry can map .js incorrectly. Force stable types for module loading.
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".js": "text/javascript",
        ".mjs": "text/javascript",
        ".css": "text/css",
        ".json": "application/json",
        ".html": "text/html; charset=utf-8",
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def guess_type(self, path: str) -> str:
        suffix = Path(path).suffix.lower()
        if suffix in self.extensions_map:
            return self.extensions_map[suffix]

        guessed, _ = mimetypes.guess_type(path)
        if guessed:
            return guessed

        return "application/octet-stream"

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main() -> None:
    with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
        print("---------------------------------------------------------")
        print(f"   UI Test server running at http://localhost:{PORT}")
        print(f"   Serving: {ROOT}")
        print("   Press Ctrl+C to stop")
        print("---------------------------------------------------------")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down UI Test server...")
            httpd.shutdown()
        finally:
            httpd.server_close()
            print("Server stopped.")


if __name__ == "__main__":
    main()
