#!/usr/bin/env python3
"""Regression tests for Windows export structure validation."""

from __future__ import annotations

import struct
import sys
import tempfile
import json
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.validate_windows_export import inspect_windows_export
from tools.capture_validation import write_rgb_png
from tools.package_windows_portable import package_windows_portable
from tools.validate_windows_gui_capture import validate_capture
from tools.validate_windows_distribution import inspect_windows_distribution


def write_fixture(path: Path, machine: int = 0x8664) -> None:
    executable = bytearray(256)
    executable[:2] = b"MZ"
    struct.pack_into("<I", executable, 0x3C, 0x80)
    executable[0x80:0x84] = b"PE\0\0"
    struct.pack_into("<H", executable, 0x84, machine)
    pack = b"GDPC" + bytes(128)
    path.write_bytes(executable + pack + struct.pack("<Q", len(pack)) + b"GDPC")


def main() -> int:
    export_presets = (Path(__file__).resolve().parents[1] / "export_presets.cfg").read_text(encoding="utf-8")
    assert export_presets.count('include_filter="assets/temporary/selected-audio/*.oggstr,assets/temporary/selected-vfx/*.pngdata"') == 2
    assert export_presets.count("assets/temporary/kenney/*") == 2

    with tempfile.TemporaryDirectory() as temporary_directory:
        root = Path(temporary_directory)
        valid = root / "valid.exe"
        write_fixture(valid)
        details = inspect_windows_export(valid, minimum_size=1)
        assert details["machine"] == 0x8664 and details["pck_bytes"] == 132

        wrong_architecture = root / "wrong-architecture.exe"
        write_fixture(wrong_architecture, machine=0x014C)
        try:
            inspect_windows_export(wrong_architecture, minimum_size=1)
        except AssertionError:
            pass
        else:
            raise AssertionError("32-bit Windows exports should be rejected")

        missing_pack = root / "missing-pack.exe"
        missing_pack.write_bytes(valid.read_bytes()[:-4] + b"NOPE")
        try:
            inspect_windows_export(missing_pack, minimum_size=1)
        except AssertionError:
            pass
        else:
            raise AssertionError("Windows exports without the embedded PCK footer should be rejected")

        portable_archive = root / "market-of-ash-windows.zip"
        package_readme = root / "README.md"
        package_readme.write_text(
            "# Market of Ash 0.14.0 — Early Access Candidate\n"
            "## Install\n## Upgrade and save compatibility\n## Rollback\n## Known limitations\n",
            encoding="utf-8",
        )
        extracted = package_windows_portable(valid, package_readme, portable_archive, root / "clean")
        assert extracted.read_bytes() == valid.read_bytes()
        portable_details = inspect_windows_distribution(portable_archive, minimum_executable_size=1)
        assert portable_details["executable_bytes"] == valid.stat().st_size and portable_details["readme_bytes"] > 0

        missing_readme_archive = root / "market-of-ash-windows-missing-readme.zip"
        with zipfile.ZipFile(missing_readme_archive, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.write(valid, "Market of Ash/market-of-ash.exe")
        try:
            inspect_windows_distribution(missing_readme_archive, minimum_executable_size=1)
        except AssertionError:
            pass
        else:
            raise AssertionError("Windows portable archives without the release guide should be rejected")

        extra_file_archive = root / "market-of-ash-windows-extra.zip"
        with zipfile.ZipFile(extra_file_archive, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.write(valid, "Market of Ash/market-of-ash.exe")
            archive.writestr(
                "Market of Ash/README.txt",
                "# Market of Ash 0.14.0 — Early Access Candidate\n"
                "## Install\n## Upgrade and save compatibility\n## Rollback\n## Known limitations\n",
            )
            archive.writestr("unexpected.txt", "not part of the portable contract")
        try:
            inspect_windows_distribution(extra_file_archive, minimum_executable_size=1)
        except AssertionError:
            pass
        else:
            raise AssertionError("Windows portable archives with unexpected files should be rejected")

        screenshot = root / "windows-main-menu.png"
        pixels = bytearray()
        for index in range(64):
            pixels.extend((index * 3 % 256, index * 5 % 256, index * 7 % 256))
        write_rgb_png(screenshot, (8, 8), bytes(pixels))
        metadata = root / "windows-version.json"
        metadata.write_text(
            json.dumps(
                {
                    "product_name": "Market of Ash",
                    "file_version": "0.14.0.0",
                    "product_version": "0.14.0.0",
                    "window_title": "Market of Ash",
                    "window": {"width": 8, "height": 8},
                    "capture": {"x": 1, "y": 1, "width": 8, "height": 8},
                }
            ),
            encoding="utf-8",
        )
        gui_details = validate_capture(
            screenshot,
            metadata,
            expected_width=8,
            expected_height=8,
            minimum_colors=32,
            minimum_bytes=1,
        )
        assert gui_details["dimensions"] == (8, 8)

        missing_capture_metadata = root / "windows-version-missing-capture.json"
        missing_capture_metadata.write_text(
            json.dumps(
                {
                    "product_name": "Market of Ash",
                    "file_version": "0.14.0.0",
                    "product_version": "0.14.0.0",
                    "window_title": "Market of Ash",
                    "window": {"width": 8, "height": 8},
                }
            ),
            encoding="utf-8",
        )
        try:
            validate_capture(
                screenshot,
                missing_capture_metadata,
                expected_width=8,
                expected_height=8,
                minimum_colors=32,
                minimum_bytes=1,
            )
        except AssertionError:
            pass
        else:
            raise AssertionError("Windows captures without explicit client bounds should be rejected")
    print("Windows export validator tests: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
