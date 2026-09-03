#!/usr/bin/env python3
"""Turn exported Market of Ash playtest reports into pacing evidence."""

from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path
from typing import Any


REPORT_VERSION = 7
FIRST_TRADE_TARGET_SECONDS = 5 * 60
FIRST_DEPARTURE_TARGET_SECONDS = 15 * 60
LONG_DWELL_SECONDS = 3 * 60
CAMPAIGN_MIN_SECONDS = 30 * 60
CAMPAIGN_MAX_SECONDS = 90 * 60


class ReportError(ValueError):
    pass


def _load_report(path: Path) -> dict[str, Any]:
    try:
        report = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ReportError(f"{path}: cannot read JSON report: {exc}") from exc
    if not isinstance(report, dict):
        raise ReportError(f"{path}: report root must be an object")
    if int(report.get("report_version", 0)) < REPORT_VERSION:
        raise ReportError(
            f"{path}: report version {report.get('report_version', 0)} has no pacing trace; "
            f"export version {REPORT_VERSION} or newer"
        )
    trace = report.get("pacing_trace")
    if not isinstance(trace, list):
        raise ReportError(f"{path}: pacing_trace must be an array")
    previous = -1.0
    for index, entry in enumerate(trace):
        if not isinstance(entry, dict):
            raise ReportError(f"{path}: pacing_trace[{index}] must be an object")
        elapsed = entry.get("elapsed_seconds")
        if not isinstance(elapsed, (int, float)) or elapsed < previous:
            raise ReportError(f"{path}: pacing trace times must be numeric and monotonic")
        if entry.get("kind") not in {"transition", "command"}:
            raise ReportError(f"{path}: pacing_trace[{index}] has an unsupported kind")
        previous = float(elapsed)
    return report


def _first_time(trace: list[dict[str, Any]], predicate) -> float | None:
    for entry in trace:
        if predicate(entry):
            return float(entry["elapsed_seconds"])
    return None


def _first_transition_after(
    trace: list[dict[str, Any]], screen_id: str, after: float | None
) -> float | None:
    if after is None:
        return None
    return _first_time(
        trace,
        lambda entry: entry.get("kind") == "transition"
        and entry.get("screen_id") == screen_id
        and float(entry["elapsed_seconds"]) >= after,
    )


def _transition_dwells(
    trace: list[dict[str, Any]], session_end: float
) -> list[dict[str, Any]]:
    transitions = [entry for entry in trace if entry.get("kind") == "transition"]
    dwells: list[dict[str, Any]] = []
    for index, entry in enumerate(transitions):
        start = float(entry["elapsed_seconds"])
        end = (
            float(transitions[index + 1]["elapsed_seconds"])
            if index + 1 < len(transitions)
            else session_end
        )
        dwells.append(
            {
                "context_id": str(entry.get("context_id", entry.get("screen_id", "unknown"))),
                "seconds": max(0.0, end - start),
            }
        )
    return sorted(dwells, key=lambda item: (-item["seconds"], item["context_id"]))


def analyze_report(path: Path, report: dict[str, Any]) -> dict[str, Any]:
    trace: list[dict[str, Any]] = report["pacing_trace"]
    session_end = float(
        report.get(
            "pacing_session_elapsed_seconds",
            trace[-1]["elapsed_seconds"] if trace else 0.0,
        )
    )
    first_trade = _first_time(
        trace,
        lambda entry: entry.get("kind") == "command"
        and entry.get("action_id") in {"buy_goods", "sell_goods"}
        and entry.get("outcome") == "ok",
    )
    first_departure = _first_time(
        trace,
        lambda entry: entry.get("kind") == "command"
        and entry.get("action_id") == "depart_route"
        and entry.get("outcome") == "ok",
    )
    first_event = _first_transition_after(trace, "route_event", first_departure)
    first_arrival = _first_transition_after(trace, "arrival_handoff", first_departure)
    first_return = _first_transition_after(trace, "settlement_shop", first_arrival)
    ending_time = _first_time(
        trace,
        lambda entry: entry.get("kind") == "transition"
        and entry.get("context_id") == "settlement_shop:ending",
    )
    first_bazaar = _first_time(
        trace,
        lambda entry: entry.get("kind") == "transition"
        and entry.get("screen_id") == "settlement_shop",
    )
    commands = [entry for entry in trace if entry.get("kind") == "command"]
    blocked = [entry for entry in commands if entry.get("outcome") == "blocked"]
    dwells = _transition_dwells(trace, session_end)
    active_dwells = [item for item in dwells if not item["context_id"].startswith("pause")]

    signals: list[dict[str, str]] = []
    if first_trade is None:
        signals.append(
            {
                "severity": "high",
                "code": "missing_first_trade",
                "message": "No successful purchase or sale appears in the pacing trace.",
            }
        )
    elif first_trade > FIRST_TRADE_TARGET_SECONDS:
        signals.append(
            {
                "severity": "high",
                "code": "slow_first_trade",
                "message": f"First successful trade took {first_trade:.0f}s; target is at most {FIRST_TRADE_TARGET_SECONDS}s.",
            }
        )
    if first_departure is None and session_end >= FIRST_DEPARTURE_TARGET_SECONDS:
        signals.append(
            {
                "severity": "high",
                "code": "missing_first_departure",
                "message": f"No successful departure appears in a {session_end:.0f}s session.",
            }
        )
    elif first_departure is not None and first_departure > FIRST_DEPARTURE_TARGET_SECONDS:
        signals.append(
            {
                "severity": "medium",
                "code": "slow_first_departure",
                "message": f"First departure took {first_departure:.0f}s; target is at most {FIRST_DEPARTURE_TARGET_SECONDS}s.",
            }
        )
    if first_departure is not None and first_event is None and first_arrival is None:
        signals.append(
            {
                "severity": "high",
                "code": "journey_not_delivered",
                "message": "The player committed a route but reached neither an encounter nor an arrival handoff before export.",
            }
        )
    if commands and len(blocked) / len(commands) >= 0.25 and len(blocked) >= 2:
        signals.append(
            {
                "severity": "medium",
                "code": "repeated_blocked_actions",
                "message": f"{len(blocked)}/{len(commands)} recorded commands were blocked; inspect their surrounding contexts.",
            }
        )
    if active_dwells and active_dwells[0]["seconds"] > LONG_DWELL_SECONDS:
        longest = active_dwells[0]
        signals.append(
            {
                "severity": "review",
                "code": "long_context_dwell",
                "message": f"Longest active dwell was {longest['seconds']:.0f}s in {longest['context_id']}; confirm whether this was deliberation or friction.",
            }
        )
    ending_id = str(report.get("ending_id", ""))
    effective_ending_time = ending_time if ending_time is not None else session_end
    if ending_id and effective_ending_time < CAMPAIGN_MIN_SECONDS:
        signals.append(
            {
                "severity": "review",
                "code": "short_completed_campaign",
                "message": f"Ending {ending_id} arrived in {effective_ending_time / 60.0:.1f} minutes, below the 30-minute candidate target.",
            }
        )
    elif not ending_id and session_end > CAMPAIGN_MAX_SECONDS:
        signals.append(
            {
                "severity": "review",
                "code": "long_unfinished_campaign",
                "message": f"The session passed 90 minutes without an ending; inspect whether the player was exploring or stalled.",
            }
        )

    return {
        "source": str(path),
        "game_version": str(report.get("game_version", "unknown")),
        "path": str(report.get("playtest_path_label", report.get("playtest_path_id", "unknown"))),
        "session_seconds": session_end,
        "milestones": {
            "first_bazaar": first_bazaar,
            "first_trade": first_trade,
            "first_departure": first_departure,
            "first_event": first_event,
            "first_arrival": first_arrival,
            "return_to_bazaar": first_return,
            "ending": effective_ending_time if ending_id else None,
        },
        "commands": len(commands),
        "blocked_commands": len(blocked),
        "longest_dwells": active_dwells[:5],
        "signals": signals,
        "ending_id": ending_id,
    }


def _median(values: list[float]) -> float | None:
    return statistics.median(values) if values else None


def cohort_summary(analyses: list[dict[str, Any]]) -> dict[str, Any]:
    milestone_names = list(analyses[0]["milestones"]) if analyses else []
    medians = {}
    for name in milestone_names:
        values = [
            float(analysis["milestones"][name])
            for analysis in analyses
            if analysis["milestones"][name] is not None
        ]
        medians[name] = _median(values)
    return {
        "report_count": len(analyses),
        "completed_count": sum(bool(analysis["ending_id"]) for analysis in analyses),
        "median_milestone_seconds": medians,
        "signal_counts": {
            severity: sum(
                signal["severity"] == severity
                for analysis in analyses
                for signal in analysis["signals"]
            )
            for severity in ("high", "medium", "review")
        },
    }


def _format_seconds(value: float | None) -> str:
    if value is None:
        return "not observed"
    minutes, seconds = divmod(int(round(value)), 60)
    return f"{minutes}m {seconds:02d}s"


def render_markdown(analyses: list[dict[str, Any]], cohort: dict[str, Any]) -> str:
    lines = [
        "# Market of Ash pacing analysis",
        "",
        f"Reports: {cohort['report_count']} · completed: {cohort['completed_count']}",
        "",
        "Automated timing signals identify where to inspect; they do not establish fun or comprehension.",
        "",
        "## Cohort milestones",
        "",
        "| Milestone | Median |",
        "| --- | ---: |",
    ]
    for name, value in cohort["median_milestone_seconds"].items():
        lines.append(f"| {name.replace('_', ' ').title()} | {_format_seconds(value)} |")
    for analysis in analyses:
        lines.extend(
            [
                "",
                f"## {Path(analysis['source']).name}",
                "",
                f"Build `{analysis['game_version']}` · {analysis['path']} · {_format_seconds(analysis['session_seconds'])}",
                "",
                "| Milestone | Time |",
                "| --- | ---: |",
            ]
        )
        for name, value in analysis["milestones"].items():
            lines.append(f"| {name.replace('_', ' ').title()} | {_format_seconds(value)} |")
        lines.extend(["", "Signals:"])
        if analysis["signals"]:
            for signal in analysis["signals"]:
                lines.append(f"- **{signal['severity'].upper()} · {signal['code']}** — {signal['message']}")
        else:
            lines.append("- No configured timing threshold was breached; review comprehension responses before concluding the pacing works.")
        if analysis["longest_dwells"]:
            lines.extend(["", "Longest active contexts:"])
            for dwell in analysis["longest_dwells"]:
                lines.append(f"- `{dwell['context_id']}` — {_format_seconds(dwell['seconds'])}")
    return "\n".join(lines) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reports", nargs="+", type=Path, help="exported report v7 JSON files")
    parser.add_argument("--format", choices=("markdown", "json"), default="markdown")
    args = parser.parse_args(argv)
    try:
        analyses = [analyze_report(path, _load_report(path)) for path in args.reports]
    except ReportError as exc:
        print(f"Pacing analysis failed: {exc}", file=sys.stderr)
        return 2
    cohort = cohort_summary(analyses)
    if args.format == "json":
        print(json.dumps({"cohort": cohort, "reports": analyses}, indent=2, sort_keys=True))
    else:
        print(render_markdown(analyses, cohort), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
