#!/usr/bin/env python3
"""Backward-compatible wrapper for the happy-path E2E smoke runner."""

from happy_path_e2e import main


if __name__ == "__main__":
    raise SystemExit(main())
