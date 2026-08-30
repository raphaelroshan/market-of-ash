#!/usr/bin/env python3
"""Regression tests for repository policy helpers."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.policy_check import contains_secret, valid_windows_version


def main() -> int:
    for version in ("0", "0.9", "0.9.0", "0.9.0.0", "12.34.56.78"):
        assert valid_windows_version(version), version
    for version in ("", "0.9.0-alpha", "0..9", ".9.0", "0.9.0.0.1", "v0.9.0"):
        assert not valid_windows_version(version), version
    assert not contains_secret("departure-desk-large-text-1280x720.png")
    assert contains_secret("token=" + "s" + "k-" + "a" * 24)
    print("Repository policy helper tests: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
