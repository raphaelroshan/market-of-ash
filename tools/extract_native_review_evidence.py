#!/usr/bin/env python3
"""Extract a compact, auditable review sequence from a validated native capture."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path


STATE_KEYS = (
    "screen",
    "intro_page",
    "settlement_id",
    "trade_receipt_title",
    "travel_phase",
    "pending_event_id",
    "arms_escalation",
    "ending_id",
)


def extract_review_evidence(manifest_path: Path, output_dir: Path, screens: list[str]) -> Path:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    captures = manifest.get("captures", [])
    by_screen = {
        str(capture.get("screen", "")): capture
        for capture in captures
        if isinstance(capture, dict)
    }
    missing = [screen for screen in screens if screen not in by_screen]
    if missing:
        raise ValueError(f"native manifest is missing review screens: {', '.join(missing)}")

    output_dir.mkdir(parents=True, exist_ok=True)
    extracted: list[dict[str, object]] = []
    source_root = manifest_path.parent.resolve()
    for index, screen in enumerate(screens, start=1):
        capture = by_screen[screen]
        source_name = str(capture.get("file", ""))
        source_path = (source_root / source_name).resolve()
        if source_path.parent != source_root or not source_path.is_file():
            raise ValueError(f"unsafe or missing capture file for {screen}: {source_name}")
        destination_name = f"{index:02d}_{screen}.png"
        shutil.copy2(source_path, output_dir / destination_name)
        ui_state = capture.get("ui_state", {})
        state_summary = {
            key: ui_state.get(key)
            for key in STATE_KEYS
            if isinstance(ui_state, dict) and key in ui_state
        }
        extracted.append(
            {
                "screen": screen,
                "file": destination_name,
                "bytes": (output_dir / destination_name).stat().st_size,
                "completion": capture.get("completion", {}),
                "state": state_summary,
                "layout": capture.get("layout", {}),
            }
        )

    review_manifest = {
        "manifest_version": 1,
        "source_manifest_version": manifest.get("manifest_version"),
        "platform": manifest.get("platform"),
        "display_scale": manifest.get("display_scale"),
        "reported_viewport": manifest.get("reported_viewport"),
        "capture_contract": manifest.get("capture_contract"),
        "screens": screens,
        "captures": extracted,
    }
    output_path = output_dir / "capture-manifest.json"
    output_path.write_text(json.dumps(review_manifest, indent=2) + "\n", encoding="utf-8")
    return output_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--screen", action="append", dest="screens", required=True)
    args = parser.parse_args()
    output_path = extract_review_evidence(args.manifest, args.output_dir, args.screens)
    print(f"Review evidence: PASS ({len(args.screens)} states, {output_path})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
