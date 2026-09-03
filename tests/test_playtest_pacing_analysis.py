#!/usr/bin/env python3

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from analyze_playtest_pacing import ReportError, _load_report, analyze_report, cohort_summary


def _entry(seconds, kind, screen, context, action_id=None, outcome=None):
    entry = {
        "elapsed_seconds": seconds,
        "kind": kind,
        "screen_id": screen,
        "context_id": context,
        "day": 1,
        "settlement_id": "ashgate",
    }
    if action_id is not None:
        entry["action_id"] = action_id
    if outcome is not None:
        entry["outcome"] = outcome
    return entry


def _report(trace, session_seconds=1800, ending_id="ending_open_routes"):
    return {
        "report_version": 7,
        "game_version": "test",
        "playtest_path_label": "Guided Trade",
        "pacing_session_elapsed_seconds": session_seconds,
        "pacing_trace": trace,
        "ending_id": ending_id,
    }


class PlaytestPacingAnalysisTests(unittest.TestCase):
    def test_extracts_complete_first_journey(self):
        trace = [
            _entry(0, "transition", "introduction", "introduction:1"),
            _entry(20, "transition", "introduction", "introduction:2"),
            _entry(40, "transition", "introduction", "introduction:3"),
            _entry(60, "transition", "settlement_shop", "settlement_shop:trade"),
            _entry(90, "command", "settlement_shop", "settlement_shop:trade", "buy_goods", "ok"),
            _entry(150, "transition", "departure_desk", "departure_desk"),
            _entry(180, "command", "route_travel", "route_travel:moving_out", "depart_route", "ok"),
            _entry(210, "transition", "route_travel", "route_travel:road"),
            _entry(240, "transition", "route_event", "route_event:three_riders_no_banner"),
            _entry(270, "command", "arrival_handoff", "arrival_handoff:reedwatch", "resolve_event", "ok"),
            _entry(270, "transition", "arrival_handoff", "arrival_handoff:reedwatch"),
            _entry(300, "transition", "settlement_shop", "settlement_shop:trade"),
            _entry(330, "command", "settlement_shop", "settlement_shop:trade", "sell_goods", "ok"),
            _entry(1700, "transition", "settlement_shop", "settlement_shop:ending"),
        ]
        analysis = analyze_report(Path("complete.json"), _report(trace))
        self.assertEqual(analysis["milestones"]["first_trade"], 90)
        self.assertEqual(analysis["milestones"]["first_departure"], 180)
        self.assertEqual(analysis["milestones"]["first_event"], 240)
        self.assertEqual(analysis["milestones"]["first_arrival"], 270)
        self.assertEqual(analysis["milestones"]["return_to_bazaar"], 300)
        self.assertEqual(analysis["milestones"]["ending"], 1700)
        self.assertFalse(any(signal["severity"] == "high" for signal in analysis["signals"]))

    def test_flags_slow_trade_and_repeated_blocks(self):
        trace = [
            _entry(0, "transition", "introduction", "introduction:1"),
            _entry(400, "transition", "settlement_shop", "settlement_shop:trade"),
            _entry(410, "command", "settlement_shop", "settlement_shop:trade", "buy_goods", "blocked"),
            _entry(420, "command", "settlement_shop", "settlement_shop:trade", "buy_goods", "blocked"),
            _entry(430, "command", "settlement_shop", "settlement_shop:trade", "buy_goods", "ok"),
            _entry(440, "command", "settlement_shop", "settlement_shop:trade", "use_settlement_action", "ok"),
        ]
        analysis = analyze_report(Path("slow.json"), _report(trace, 1000, ""))
        codes = {signal["code"] for signal in analysis["signals"]}
        self.assertIn("slow_first_trade", codes)
        self.assertIn("missing_first_departure", codes)
        self.assertIn("repeated_blocked_actions", codes)
        self.assertIn("long_context_dwell", codes)

    def test_rejects_legacy_or_non_monotonic_reports(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            legacy_path = Path(temp_dir) / "legacy.json"
            legacy_path.write_text(json.dumps({"report_version": 6}), encoding="utf-8")
            with self.assertRaises(ReportError):
                _load_report(legacy_path)
            invalid_path = Path(temp_dir) / "invalid.json"
            invalid_path.write_text(
                json.dumps(
                    _report(
                        [
                            _entry(10, "transition", "main_menu", "main_menu"),
                            _entry(5, "transition", "introduction", "introduction:1"),
                        ]
                    )
                ),
                encoding="utf-8",
            )
            with self.assertRaises(ReportError):
                _load_report(invalid_path)

    def test_cli_outputs_markdown_and_cohort_medians(self):
        trace = [
            _entry(0, "transition", "settlement_shop", "settlement_shop:trade"),
            _entry(60, "command", "settlement_shop", "settlement_shop:trade", "buy_goods", "ok"),
        ]
        with tempfile.TemporaryDirectory() as temp_dir:
            report_path = Path(temp_dir) / "report.json"
            report_path.write_text(json.dumps(_report(trace)), encoding="utf-8")
            result = subprocess.run(
                [sys.executable, str(ROOT / "tools" / "analyze_playtest_pacing.py"), str(report_path)],
                check=False,
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("# Market of Ash pacing analysis", result.stdout)
        self.assertIn("First Trade", result.stdout)
        cohort = cohort_summary(
            [
                analyze_report(Path("one.json"), _report(trace)),
                analyze_report(Path("two.json"), _report([trace[0], {**trace[1], "elapsed_seconds": 120}])),
            ]
        )
        self.assertEqual(cohort["median_milestone_seconds"]["first_trade"], 90)


if __name__ == "__main__":
    unittest.main()
